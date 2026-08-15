#!/usr/bin/env bash
# boot.sh — boot the NVIDIA GB200NVL BMC (OpenBMC) from its full flash image.
#
# WHAT : flash-boot (u-boot+kernel+rootfs in the .mtd) on QEMU's custom gb200nvl-bmc machine (AST2600).
#        Console on the first serial; sshd, Redfish, IPMI-LAN + the NVIDIA OEM handlers (NetFn 0x3C) all
#        come up. snapshot=on -> writes discarded, clean every boot.
# RUN  : BG=1 ./boot.sh   (background; console -> $WD/svc.log ; drive via $WD/cin)
set -u
_HERE="$(cd "$(dirname "$0")" && pwd)"; _REPO="$(cd "$_HERE/../.." && pwd)"
WD="${WD:-$_REPO/work/$(basename "$_HERE")}"
IP="${IP:-127.0.0.1}"
SSH_PORT="${SSH_PORT:-8022}"; HTTPS_PORT="${HTTPS_PORT:-8443}"; IPMI_PORT="${IPMI_PORT:-8623}"
FLASH="$WD/flash.mtd"
[ -f "$FLASH" ] || { echo "no $FLASH — run ./build.sh nvidia-obmc first"; exit 1; }

# gb200nvl-bmc exposes two UARTs; console is the first (-> log), the second is unused (-> null).
# Explicit -serial (not -nographic) so the console is captured cleanly on this custom machine.
QEMU=(qemu-system-arm -M gb200nvl-bmc -m 1024 -display none
  -drive "file=$FLASH,format=raw,if=mtd,snapshot=on"
  -net nic -net "user,hostfwd=tcp:$IP:$SSH_PORT-:22,hostfwd=tcp:$IP:$HTTPS_PORT-:443,hostfwd=udp:$IP:$IPMI_PORT-:623,hostname=nvidia-obmc")

if [ "${BG:-}" = 1 ]; then
  cd "$WD"; : > svc.log
  "${QEMU[@]}" -serial "file:$WD/svc.log" -serial null &
  echo "backgrounded. console log -> $WD/svc.log ; ssh: root/0penBmc on $IP:$SSH_PORT (primary access)"
else
  exec "${QEMU[@]}" -serial mon:stdio -serial null
fi
