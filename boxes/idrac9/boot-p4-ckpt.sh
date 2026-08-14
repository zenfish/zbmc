#!/usr/bin/env bash
# boot-p4-ckpt.sh — idrac9 warm-restore snapshot of the P4 IPMI/RAKP box (NOT the flaky P6 Redfish).
# Mirrors idrac10's boot-live-ckpt.sh: PERSISTENT qcow2 overlay (so disk stays consistent with the
# migrated RAM — the snapshot=on divergence is what killed the P6 restore), patched qemu (migratable
# usb-net -> network survives restore, NO_UNPLUG), boot until fullfw answers RAKP, then QMP-migrate.
# USAGE: ./boot-p4-ckpt.sh [max_ipmi_wait_polls]   (default ~180 polls x 5s after boot)
# SUCCESS: prints "SNAPSHOT SAVED". RELATED: restore-idrac9.sh, ckpt.py, boot-live-ckpt.sh (idrac10).
set -euo pipefail
cd "$(dirname "$0")"
QB=./qemu-system-arm-patched
K=915f32f49a97456d0d6d66eee5ed84c894b414af
W="${HOME}/phd/tmp/idrac9-virtual/ckpt"; mkdir -p "$W"
OVL="$W/overlay.qcow2"; STATE="$W/state-p4.gz"; FROZEN="$W/overlay-frozen.qcow2"
QMP=/tmp/vbmc-idrac9-ckpt-qmp.sock
[ -x "$QB" ] || { echo "patched qemu missing — build-qemu-patched.sh" >&2; exit 1; }
[ -f boot/initramfs.p4.xz ] || { echo "no initramfs.p4.xz — vbmc idrac9 build" >&2; exit 1; }
DTB=boot/p4.dtb; [ -f "$DTB" ] || DTB=boot/p2uni.dtb

pkill -9 -f 'qemu-system-arm.*ckpt-qmp' 2>/dev/null || true; sleep 1
rm -f "$QMP" "$OVL" /tmp/idrac9-p4boot.log
# PERSISTENT overlay over the raw base (frozen at snapshot -> every restore identical + disk-consistent)
qemu-img create -f qcow2 -F raw -b "$(pwd)/img/sd256.img" "$OVL" >/dev/null

echo "[1] cold-boot P4 (patched qemu, persistent overlay, wildcard hostfwd)"
nohup "$QB" -M npcm750-evb -m 1G -display none \
  -kernel boot/uImage.patched -dtb "$DTB" -initrd boot/initramfs.p4.xz \
  -drive "id=rootsd,if=none,file=$OVL,format=qcow2" -device sd-card,drive=rootsd,bus=sd-bus \
  -netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=udp::6623-:623,hostfwd=tcp::6443-:443 \
  -device usb-net,netdev=n1,bus=usb-bus.0,id=nic0 \
  -rtc base=2020-09-20T05:00:00,clock=vm \
  -qmp unix:"$QMP",server,nowait -serial file:/tmp/idrac9-p4boot.log \
  -serial unix:/tmp/vbmc-idrac9-ttyS1.sock,server,nowait >/tmp/idrac9-p4qemu.log 2>&1 &
QPID=$!
for i in $(seq 1 30); do [ -S "$QMP" ] && break; sleep 0.5; done

echo "[2] wait for fullfw RAKP (poll zipmi mc info on :6623, up to ~18min)"
POLLS="${1:-200}"; ok=0
for i in $(seq 1 "$POLLS"); do
  zipmi -H 127.0.0.1 -p 6623 -C 17 -I lanplus -U root -K "$K" -t 8 mc info 2>/dev/null \
    | grep -qiE 'Manufacturer|Device Available' && { echo "  IPMI up at poll $i (~$((i*5))s of polling)"; ok=1; break; }
  sleep 5
done
[ $ok = 1 ] || { echo "IPMI NEVER CAME UP — see /tmp/idrac9-p4boot.log"; grep -aE 'gate|fullfw|Reached target' /tmp/idrac9-p4boot.log | tail -5; exit 1; }

echo "[3] confirm reliable (5 calls)"
n=0; for j in $(seq 1 5); do
  zipmi -H 127.0.0.1 -p 6623 -C 17 -I lanplus -U root -K "$K" -t 10 mc info 2>/dev/null | grep -qiE 'Manufacturer|Device Available' && n=$((n+1))
done
echo "  IPMI reliability: $n/5"
[ $n -ge 3 ] || { echo "IPMI weak — box not warm enough to snapshot"; exit 1; }

echo "[4] snapshot via ckpt.py save NO_UNPLUG (usb-net migrates -> net survives restore)"
QEMU_NO_UNPLUG=1 python3 ckpt.py save "$QMP" "$STATE" 2>&1 | sed 's/^/  /'
[ -s "$STATE" ] || { echo "save produced no state"; exit 1; }
cp "$OVL" "$FROZEN"          # freeze disk state at the snapshot instant
ls -lh "$STATE" | awk '{print "  state:",$5}'
echo "SNAPSHOT SAVED $STATE  (frozen overlay $FROZEN; source box still live on :6623)"
