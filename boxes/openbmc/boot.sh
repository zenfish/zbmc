#!/usr/bin/env bash
# boot.sh — boot vanilla upstream OpenBMC (Phosphor, AST2600) from its full flash image.
#
# WHAT : the .mtd is a complete flash (u-boot + kernel + rootfs), so QEMU's ast2600-evb boots it
#        directly — no kernel/dtb carving. Console is ttyS4; sshd, Redfish (bmcweb) and IPMI-LAN come
#        up on their own. snapshot=on means writes are discarded, so every boot is clean + repeatable.
# WHY  : the clean baseline (Manufacturer ID 0, no OEM) — and the first turnkey box with working network.
# RUN  : BG=1 ./boot.sh   (background; console -> $WD/svc.log ; drive via $WD/cin)
set -u
_HERE="$(cd "$(dirname "$0")" && pwd)"; _REPO="$(cd "$_HERE/../.." && pwd)"
WD="${WD:-$_REPO/work/$(basename "$_HERE")}"
IP="${IP:-127.0.0.1}"
SSH_PORT="${SSH_PORT:-7022}"; HTTPS_PORT="${HTTPS_PORT:-7443}"; IPMI_PORT="${IPMI_PORT:-7623}"
FLASH="$WD/flash.mtd"
[ -f "$FLASH" ] || { echo "no $FLASH — run ./build.sh openbmc first"; exit 1; }

QEMU=(qemu-system-arm -M ast2600-evb -m 1024 -nographic
  -drive "file=$FLASH,format=raw,if=mtd,snapshot=on"
  -net nic -net "user,hostfwd=tcp:$IP:$SSH_PORT-:22,hostfwd=tcp:$IP:$HTTPS_PORT-:443,hostfwd=udp:$IP:$IPMI_PORT-:623,hostname=openbmc")

if [ "${BG:-}" = 1 ]; then
  cd "$WD"; rm -f cin; mkfifo cin; : > svc.log
  ( tail -f cin ) | "${QEMU[@]}" > svc.log 2>&1 &
  echo "backgrounded. console -> $WD/svc.log ; ssh: root/0penBmc on $IP:$SSH_PORT"
else
  exec "${QEMU[@]}"
fi
