#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${WD:-$ROOT/work/irmc-fujitsu}"
QEMU_BIN="${ZBMC_QEMU:-qemu-system-arm}"
IP="${IP:-127.0.0.1}"
SSH_PORT="${SSH_PORT:-5022}"
HTTPS_PORT="${HTTPS_PORT:-5443}"
IPMI_PORT="${IPMI_PORT:-5623}"
SOCK="${SOCK:-$WD/serial.sock}"
QMP="${QMP:-$WD/qmp.sock}"
CONSOLE_LOG="${ZBMC_CONSOLE_LOG:-$WD/console.log}"
LAUNCH_LOG="${LOG:-$WD/launcher.log}"

for file in kernel.bin system-patched.dtb initramfs.cpio.gz flash64.img rootfs-sd.img; do
  [ -f "$WD/$file" ] || { echo "missing $WD/$file - run: zbmc irmc-fujitsu build" >&2; exit 1; }
done

rm -f "$SOCK" "$QMP"
nohup "$QEMU_BIN" \
  -M ast2600-evb,fmc-model=w25q512jv -m 1024 \
  -kernel "$WD/kernel.bin" -dtb "$WD/system-patched.dtb" \
  -initrd "$WD/initramfs.cpio.gz" \
  -append 'console=ttyS4,115200n8 earlycon=uart8250,mmio32,0x1e784000,115200n8 imagebooted=1 nosmp irqchip.gicv2_force_probe=1 loglevel=7 hung_task_panic=0 hung_task_timeout_secs=0 irmc_no_redfish' \
  -drive "file=$WD/flash64.img,format=raw,if=mtd,snapshot=on" \
  -drive "file=$WD/rootfs-sd.img,format=raw,if=sd,snapshot=on" \
  -display none -monitor none \
  -qmp "unix:$QMP,server=on,wait=off" \
  -nic user -nic user \
  -nic "user,net=192.168.2.0/24,host=192.168.2.2,hostname=irmc-fujitsu,hostfwd=udp:$IP:$IPMI_PORT-:623,hostfwd=tcp:$IP:$HTTPS_PORT-:443,hostfwd=tcp:$IP:$SSH_PORT-:22" \
  -chardev "socket,id=serial0,path=$SOCK,server=on,wait=off,logfile=$CONSOLE_LOG,logappend=off" \
  -serial chardev:serial0 -no-reboot >"$LAUNCH_LOG" 2>&1 &
echo "$!"
