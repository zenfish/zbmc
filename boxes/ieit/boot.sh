#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${WD:-$ROOT/work/ieit}"
QEMU_BIN="${ZBMC_QEMU:-${QEMU:-qemu-system-arm}}"
IP="${IP:-127.0.0.1}"
SSH_PORT="${SSH_PORT:-5022}"
HTTPS_PORT="${HTTPS_PORT:-5443}"
IPMI_PORT="${IPMI_PORT:-5623}"
SOCK="${SOCK:-$WD/serial.sock}"
QMP="${QMP:-$WD/qmp.sock}"
CONSOLE_LOG="${ZBMC_CONSOLE_LOG:-$WD/console.log}"
LAUNCH_LOG="${LOG:-$WD/launcher.log}"

for file in ieit-runtime.ima kernel.uimage service-ramdisk.uimage; do
    [ -f "$WD/$file" ] || { echo "missing $WD/$file - run: zbmc ieit build" >&2; exit 1; }
done
rm -f "$SOCK" "$QMP"

nohup "$QEMU_BIN" \
    -M ast2500-evb,fmc-model=mx66l51235f,bmc-console=uart5 \
    -snapshot -drive "file=$WD/ieit-runtime.ima,if=mtd,format=raw" \
    -device "loader,file=$WD/kernel.uimage,addr=0x83000000,force-raw=on" \
    -device "loader,file=$WD/service-ramdisk.uimage,addr=0x85000000,force-raw=on" \
    -display none -monitor none \
    -qmp "unix:$QMP,server=on,wait=off" \
    -nic "user,hostname=ieit,hostfwd=tcp:$IP:$SSH_PORT-:22,hostfwd=tcp:$IP:$HTTPS_PORT-:443,hostfwd=udp:$IP:$IPMI_PORT-:623" \
    -chardev "socket,id=serial0,path=$SOCK,server=on,wait=off,logfile=$CONSOLE_LOG,logappend=off" \
    -serial chardev:serial0 >"$LAUNCH_LOG" 2>&1 &
echo "$!"
