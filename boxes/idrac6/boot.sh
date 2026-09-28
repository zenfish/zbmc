#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${WD:-$ROOT/work/idrac6}"
QEMU_BIN="${ZBMC_QEMU:-${QEMU:-qemu-system-arm}}"
IP="${IP:-10.0.9.6}"
GATEWAY="${GATEWAY:-10.0.0.1}"
TAP="${TAP:-ztap-idrac6}"
MAC="${MAC:-52:54:00:fa:00:29}"
SOCK="${SOCK:-$WD/serial.sock}"
QMP="${QMP:-$WD/qmp.sock}"
CONSOLE_LOG="${ZBMC_CONSOLE_LOG:-$WD/console.log}"
LAUNCH_LOG="${LOG:-$WD/launcher.log}"

for file in vmlinuz-2.6.26-2-versatile idrac6-initramfs.cpio.gz; do
  [ -f "$WD/$file" ] || { echo "missing $WD/$file - run: zbmc idrac6 build" >&2; exit 1; }
done
rm -f "$SOCK" "$QMP"

nohup "$QEMU_BIN" -M versatilepb -m 128M \
  -kernel "$WD/vmlinuz-2.6.26-2-versatile" \
  -initrd "$WD/idrac6-initramfs.cpio.gz" \
  -append "console=ttyAMA0 rdinit=/init zbmc_ip=$IP zbmc_gateway=$GATEWAY" \
  -display none -monitor none -audio none -no-reboot \
  -qmp "unix:$QMP,server=on,wait=off" \
  -netdev "tap,id=bmcnet,ifname=$TAP,script=no,downscript=no" \
  -net "nic,model=smc91c111,netdev=bmcnet,macaddr=$MAC" \
  -chardev "socket,id=serial0,path=$SOCK,server=on,wait=off,logfile=$CONSOLE_LOG,logappend=off" \
  -serial chardev:serial0 >"$LAUNCH_LOG" 2>&1 &
echo "$!"
