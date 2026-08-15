#!/usr/bin/env bash
# boot.sh — boot the HPE XD670 MegaRAC SP-X BMC (AST2600) with real init + networking.
#
# WHAT : direct-kernel boot — rootfs squashfs as a RAM disk; /conf & /bkupconf mount from the NAMED mtd
#        partitions in mtdflash.bin. Console ttyS4 (getty sysadmin/superuser). sshd is loopback-only under
#        emulation, so the console is the shell; IPMI 2.0 RMCP+ + authed Redfish work (admin/superuser).
# KEY  : mtdparts NAMES must match build.sh's layout — MegaRAC mountall greps /proc/mtd for conf/bkupconf.
# RUN  : BG=1 ./boot.sh   (background; console -> $WD/svc.log ; drive via $WD/cin)
set -u
_HERE="$(cd "$(dirname "$0")" && pwd)"; _REPO="$(cd "$_HERE/../.." && pwd)"
WD="${WD:-$_REPO/work/$(basename "$_HERE")}"
IP="${IP:-127.0.0.1}"
SSH_PORT="${SSH_PORT:-5022}"; HTTPS_PORT="${HTTPS_PORT:-5443}"; IPMI_PORT="${IPMI_PORT:-5623}"
[ -f "$WD/mtdflash.bin" ] || { echo "no artifacts in $WD — run ./build.sh megarac-hpe first"; exit 1; }

# fresh pristine flash each boot so /conf starts clean -> IPMIMain auto-provisions admin/superuser.
cp -f "$WD/mtdflash.bin" "$WD/mtdflash-run.bin"
MTDPARTS='mtdparts=1e620000.spi:1M(uboot),2M(conf),2M(bkupconf),1M(extlog),4M(www),-(root)'
APPEND="console=ttyS4,115200n8 root=/dev/ram0 ro rootfstype=squashfs ramdisk_size=131072 ramdisk_blocksize=4096 $MTDPARTS maxcpus=1 rootwait"
QEMU=(qemu-system-arm -M ast2600-evb -m 1024 -nographic
  -kernel "$WD/kernel.Image" -dtb "$WD/dtb-a1.dtb" -initrd "$WD/rootfs.sqfs"
  -drive "file=$WD/mtdflash-run.bin,format=raw,if=mtd"
  -net nic -net "user,hostfwd=tcp:$IP:$SSH_PORT-:22,hostfwd=tcp:$IP:$HTTPS_PORT-:443,hostfwd=udp:$IP:$IPMI_PORT-:623,hostname=megarac-hpe"
  -append "$APPEND")

if [ "${BG:-}" = 1 ]; then
  cd "$WD"; rm -f cin; mkfifo cin; : > svc.log
  ( tail -f cin ) | "${QEMU[@]}" > svc.log 2>&1 &
  echo "backgrounded. console -> $WD/svc.log ; drive: echo 'cmd' > $WD/cin ; login sysadmin/superuser"
else
  exec "${QEMU[@]}"
fi
