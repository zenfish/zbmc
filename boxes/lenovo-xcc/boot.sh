#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${WD:-$ROOT/work/lenovo-xcc}"
QEMU_BIN="${ZBMC_QEMU:-qemu-system-arm}"
IP="${IP:-127.0.0.1}"
SSH_PORT="${SSH_PORT:-5022}"
HTTPS_PORT="${HTTPS_PORT:-5443}"
IPMI_PORT="${IPMI_PORT:-5623}"
SOCK="${SOCK:-$WD/serial.sock}"
QMP="${QMP:-$WD/qmp.sock}"
CONSOLE_LOG="${ZBMC_CONSOLE_LOG:-$WD/console.log}"
LAUNCH_LOG="${LOG:-$WD/launcher.log}"

for file in kernel.zImage xcc.dtb sram.bin ptables.bin emmc.qcow2; do
  [ -f "$WD/$file" ] || { echo "missing $WD/$file - run: zbmc lenovo-xcc build" >&2; exit 1; }
done

rm -f "$SOCK" "$QMP"
nohup "$QEMU_BIN" \
  -M "ast2600-evb,xcc-fpga=true,xcc-ptables-file=$WD/ptables.bin" -m 1G \
  -kernel "$WD/kernel.zImage" -dtb "$WD/xcc.dtb" \
  -append 'console=ttyS4,115200 earlyprintk clk_ignore_unused loglevel=8' \
  -drive "file=$WD/emmc.qcow2,format=qcow2,if=sd,snapshot=on" \
  -global emmc.boot-partition-size=4194304 \
  -global emmc.gp0-partition-size=3565158400 \
  -device "loader,file=$WD/sram.bin,addr=0x10000000,force-raw=on" \
  -netdev "user,id=net0,hostname=lenovo-xcc,hostfwd=tcp:$IP:$SSH_PORT-:22,hostfwd=tcp:$IP:$HTTPS_PORT-:443,hostfwd=udp:$IP:$IPMI_PORT-:623" \
  -net nic,model=ftgmac100,netdev=net0,macaddr=52:54:00:12:34:60 \
  -netdev user,id=net1 -net nic,model=ftgmac100,netdev=net1,macaddr=52:54:00:12:34:61 \
  -netdev user,id=net2 -net nic,model=ftgmac100,netdev=net2,macaddr=52:54:00:12:34:62 \
  -netdev user,id=net3 -net nic,model=ftgmac100,netdev=net3,macaddr=52:54:00:12:34:63 \
  -display none -monitor none \
  -qmp "unix:$QMP,server=on,wait=off" \
  -chardev "socket,id=serial0,path=$SOCK,server=on,wait=off,logfile=$CONSOLE_LOG,logappend=off" \
  -serial chardev:serial0 -no-reboot >"$LAUNCH_LOG" 2>&1 &
echo "$!"
