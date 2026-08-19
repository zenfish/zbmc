#!/usr/bin/env bash
# restore-idrac9.sh — bring back the warm idrac9 P4 IPMI snapshot in ~15s instead of the ~15min cold
# boot + fullfw warm-up. Uses the PATCHED qemu (migratable usb-net) so the NIC is in the saved state
# and host network (ipmi/ssh) survives restore (NO_UNPLUG). Disk = the FROZEN qcow2 overlay from
# boot-p4-ckpt.sh with snapshot=on (kept consistent with the migrated RAM — snapshot=on over the RAW
# base diverges and kills the guest, which is what broke the earlier P6 attempt).
# USAGE: ./restore-idrac9.sh [bind_ip]
#   bind_ip empty -> wildcard 2222/6623/6443 on 127.0.0.1 (test, non-root)
#   bind_ip set   -> hostfwd on BIND:{623} as root for zbmc (10.0.9.9). NB: :22 collides with the Mac's
#                    own sshd, so the real-IP path forwards IPMI(623) only; use ttyS1/2222 for a shell.
# SUCCESS: prints "RESTORE OK: ipmi=N/5" with N>0. RELATED: boot-p4-ckpt.sh, ckpt.py.
set -euo pipefail
cd "$(dirname "$0")"
QB=./qemu-system-arm-patched
K=915f32f49a97456d0d6d66eee5ed84c894b414af
W="${HOME}/phd/tmp/idrac9-virtual/ckpt"
STATE="${STATE:-$W/state-p4.gz}"; FROZEN="$W/overlay-frozen.qcow2"
QMP=/tmp/zbmc-idrac9-rqmp.sock
[ -s "$STATE" ] || { echo "no snapshot at $STATE — run ./boot-p4-ckpt.sh first" >&2; exit 1; }
[ -s "$FROZEN" ] || { echo "no frozen overlay at $FROZEN — run ./boot-p4-ckpt.sh first" >&2; exit 1; }
[ -x "$QB" ] || { echo "patched qemu missing ($QB) — build-qemu-patched.sh" >&2; exit 1; }
DTB=boot/p4.dtb; [ -f "$DTB" ] || DTB=boot/p2uni.dtb
BIND="${1:-}"
if [ -n "$BIND" ]; then HF="hostfwd=udp:$BIND:623-:623,hostfwd=tcp:$BIND:443-:443"; SP=623; VIP="$BIND"
else HF="hostfwd=tcp::2222-:22,hostfwd=udp::6623-:623,hostfwd=tcp::6443-:443"; SP=6623; VIP=127.0.0.1; fi
SUDO=""; [ -n "$BIND" ] && [ "$(id -u)" -ne 0 ] && SUDO="sudo -n"
$SUDO pkill -9 -f 'qemu-system-arm.*rqmp' 2>/dev/null || true
$SUDO pkill -9 -f "$HF" 2>/dev/null || true
sleep 1; $SUDO rm -f "$QMP" 2>/dev/null; rm -f "$QMP" 2>/dev/null || true
$SUDO nohup "$QB" -M npcm750-evb -m 1G -display none \
  -kernel boot/uImage.patched -dtb "$DTB" -initrd boot/initramfs.p4.xz \
  -drive "id=rootsd,if=none,file=$FROZEN,format=qcow2,snapshot=on" -device sd-card,drive=rootsd,bus=sd-bus \
  -netdev "user,id=n1,$HF" -device usb-net,netdev=n1,bus=usb-bus.0,id=nic0 \
  -rtc base=2020-09-20T05:00:00,clock=vm \
  -qmp unix:"$QMP",server,nowait -serial file:/tmp/zbmc-idrac9-console.log \
  -incoming "exec:gzip -dc < $STATE" >/tmp/zbmc-idrac9-rqemu.log 2>&1 &
QPID=$!
for i in $(seq 1 30); do $SUDO test -S "$QMP" && break; sleep 0.5; done
$SUDO test -S "$QMP" || { echo "QMP never appeared:"; $SUDO tail -3 /tmp/zbmc-idrac9-rqemu.log; exit 1; }
QEMU_NO_UNPLUG=1 $SUDO python3 ckpt.py restore-finish "$QMP" 2>&1 | sed 's/^/[restore] /'
# usb-net re-enumeration after resume is slower than gmac — poll up to ~90s
ip=0
for t in $(seq 1 18); do
  sleep 5
  ip=$(zipmi -H "$VIP" -p "$SP" -C 17 -I lanplus -U root -K "$K" -t 8 mc info 2>/dev/null | grep -aic 'Manufacturer') || ip=0
  [ "$ip" -ge 1 ] && break
done
echo "RESTORE OK: ipmi=$ip ($VIP:$SP; pid $QPID; kill: $SUDO kill $QPID)"
[ "$ip" -ge 1 ] || echo "  (IPMI 0 — usb-net may need longer, or vmstate/overlay drift; check /tmp/zbmc-idrac9-rqemu.log)"
