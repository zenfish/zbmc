#!/usr/bin/env bash
# run-p5-systemd.sh — iDRAC10 Phase 5: boot via systemd, test IPMI RAKP
#
# WHAT:  Boots iDRAC10 with real systemd init (not /usr/bin/sh).
#        systemd brings up dbus-broker → aim → fullfw (socket-activated UDP 623).
#        Host tests RAKP auth with fleet factory IPMIKey 915F32...8964.
# HOW:   Image.boot-systemd has 'init=/usr/bin/sh' stripped; /sbin/init→systemd.
# NOTE:  Most services will fail (no real HW), but dbus+aim+fullfw should start.
#        Squashfs is read-only; systemd mounts tmpfs at /run, /tmp automatically.
set -euo pipefail
cd "$(dirname "$0")"

SOCK=/tmp/idrac10-p5-systemd.sock
QEMU_IPMI_PORT=7623
FACTORY_IPMIKEY="915F32F49A97456D0D6D66EEE5ED84C894B414AFEB69DADFF891AF14F4B98964"

[ -S "$SOCK" ] && rm -f "$SOCK"

trap "pkill -f 'Image.boot-systemd' 2>/dev/null; true" EXIT

# Boot QEMU with systemd init + UDP 623 forwarded
qemu-system-aarch64 \
  -M npcm845-evb -m 1G \
  -kernel boot/Image.boot-systemd \
  -dtb boot/qemu-gmac.dtb \
  -drive "id=rootsd,if=none,file=img/sd.img,format=raw,snapshot=on" \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -display none \
  -nic user,model=npcm-gmac,"hostfwd=udp::${QEMU_IPMI_PORT}-:623" \
  -serial unix:"${SOCK}",server,nowait \
  2>/tmp/idrac10-systemd-qemu.log &
QPID=$!

until [ -S "$SOCK" ]; do sleep 0.5; done
sleep 1
echo "[+] QEMU started (systemd boot)"

# Monitor console for systemd reaching multi-user target or fullfw ready
# Give it up to 10 minutes (systemd boot + service deps)
echo "[+] Waiting for systemd + fullfw startup (max 600s)..."

OUT=/tmp/idrac10-systemd-console.log
socat - UNIX-CONNECT:"${SOCK}" 2>/dev/null | tee "$OUT" | \
    timeout 600 awk '
        /Reached target.*Multi-User/ || /fullfw.*ready/ || /IPMI.*LAN.*ready/ {
            print "[MILESTONE] " $0
        }
        { fflush() }
    ' &
SOWAIT=$!
sleep 120  # wait for systemd boot + service startup

echo ""
echo "[+] Checking if UDP 7623 (fullfw) is responding..."

# Test 1: RAKP with factory IPMIKey
echo "--- Test 1: RAKP with factory IPMIKey ---"
zipmi \
    -H localhost -p "$QEMU_IPMI_PORT" \
    -U root -K "$FACTORY_IPMIKEY" \
    -t 15 \
    chassis status 2>&1 || true
echo ""

# Test 2: wrong key control (should fail)
echo "--- Test 2: wrong key (expect failure) ---"
zipmi \
    -H localhost -p "$QEMU_IPMI_PORT" \
    -U root -K "DEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEFDEADBEEF" \
    -t 10 \
    chassis status 2>&1 || true
echo ""

# Show tail of console log
echo "--- console tail ---"
tail -30 "$OUT" 2>/dev/null || true

echo "[+] Phase 5 systemd run complete"
