#!/usr/bin/env bash
# boot-p6-ckpt.sh — regenerate the idrac9 P6 warm snapshot (Redfish-200-ready) with the CURRENT
# patched qemu, so restore-idrac9.sh works. Cold-boots via the patched binary (migratable usb-net),
# waits for ssh, runs the Redfish bring-up (start-web.sh), verifies Redfish 200 + IPMI, then
# ckpt.py save NO_UNPLUG -> img/ckpt/redfish-200-ready-net.gz (+ refresh GOLDEN-NET.sha256).
#
# WHY regenerate: QEMU migration needs the saved usb-net vmstate to match the running binary. Any
# rebuild of qemu-system-arm-patched (patch iterated / qemu bumped) invalidates old snapshots
# ("Missing section footer for usb-net"). Re-run this after any such rebuild.
# USAGE: ./boot-p6-ckpt.sh          # ~15-20min; run detached, watch /tmp/idrac9-p6ckpt.log
# SUCCESS: prints "SNAPSHOT SAVED". RELATED: restore-idrac9.sh, ckpt.py, start-web.sh, build-qemu-patched.sh.
set -euo pipefail
cd "$(dirname "$0")"
QB=./qemu-system-arm-patched
K=915f32f49a97456d0d6d66eee5ed84c894b414af
STATE=img/ckpt/redfish-200-ready-net.gz
QMP=/tmp/vbmc-idrac9-qmp.sock
# Wildcard hostfwd (2222/6623/6443) for the snapshot boot: binding real-IP :22 would collide with the
# Mac's own sshd on *:22. ssh-in.sh is pointed at 127.0.0.1:2222 via SSH_HOST/SSH_PORT so it (and
# start-web.sh) reach the GUEST, not the host. The saved state is IP-agnostic — restore/vbmc rebind
# the real IP later (only :22 collides with the Mac; IPMI 623 + Redfish 443 are fine on 10.0.9.9).
export SSH_HOST=127.0.0.1 SSH_PORT=2222
[ -x "$QB" ] || { echo "patched qemu missing — build-qemu-patched.sh" >&2; exit 1; }
DTB=boot/p4.dtb; [ -f "$DTB" ] || DTB=boot/p2uni.dtb
pkill -9 -f 'qemu-system-arm' 2>/dev/null || true; sleep 1
rm -f "$QMP" /tmp/vbmc-idrac9-ttyS1.sock /tmp/idrac9-p6boot.log 2>/dev/null || true

echo "[1] cold-boot P6 (patched qemu, wildcard 2222/6623/6443)"
nohup "$QB" -M npcm750-evb -m 1G -display none \
  -kernel boot/uImage.patched -dtb "$DTB" -initrd boot/initramfs.p6.xz \
  -drive id=rootsd,if=none,file=img/sd256.img,format=raw,snapshot=on \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=udp::6623-:623,hostfwd=tcp::6443-:443 \
  -device usb-net,netdev=n1,bus=usb-bus.0,id=nic0 \
  -rtc base=2020-09-20T05:00:00,clock=vm \
  -qmp unix:"$QMP",server,nowait -serial file:/tmp/idrac9-p6boot.log \
  -serial unix:/tmp/vbmc-idrac9-ttyS1.sock,server,nowait >/tmp/idrac9-qemu-err.log 2>&1 &
for i in $(seq 1 30); do [ -S "$QMP" ] && break; sleep 0.5; done

echo "[2] wait for ssh (up to ~15min)"
ready=0
for i in $(seq 1 90); do
  timeout 12 ./ssh-in.sh 'echo SSH_ALIVE' 2>/dev/null | grep -aq SSH_ALIVE && { ready=1; echo "  ssh ready ~$((i*10))s"; break; }
  sleep 10
done
[ $ready = 1 ] || { echo "SSH NEVER READY — aborting"; exit 1; }

echo "[3] Redfish bring-up (start-web.sh)"
./start-web.sh >/tmp/idrac9-startweb.log 2>&1 || { echo "start-web.sh FAILED — see /tmp/idrac9-startweb.log"; tail -5 /tmp/idrac9-startweb.log; exit 1; }

echo "[4] verify Redfish 200 + IPMI (wildcard ports)"
rf=$(curl -sk -u root:Calvin123# "https://127.0.0.1:6443/redfish/v1/" -o /dev/null -w '%{http_code}' --max-time 12 2>/dev/null)
ip=$(zipmi -H 127.0.0.1 -p 6623 -C 17 -I lanplus -U root -K "$K" -t 15 mc info 2>/dev/null | grep -aic 'Manufacturer Name')
echo "  redfish=$rf ipmi_mfg=$ip"
[ "$rf" = 200 ] || { echo "Redfish not 200 — not snapshotting a broken box"; exit 1; }

echo "[5] snapshot via ckpt.py save NO_UNPLUG"
QEMU_NO_UNPLUG=1 python3 ckpt.py save "$QMP" "$STATE" 2>&1 | sed 's/^/  /'
[ -s "$STATE" ] || { echo "save produced no state"; exit 1; }
# refresh the pin so restore-idrac9.sh / verify matches this binary+artifacts
shasum -a 256 "$STATE" boot/uImage.patched "$DTB" boot/initramfs.p6.xz "$QB" > img/ckpt/GOLDEN-NET.sha256
ls -lh "$STATE" | awk '{print "  state:",$5}'
echo "SNAPSHOT SAVED $STATE  (source box still live; restore: ./restore-idrac9.sh)"
