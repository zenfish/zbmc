#!/usr/bin/env bash
# boot-asmb787-svc.sh — boot the Advantech ASMB-787 MegaRAC SP-X 4.0 BMC under qemu ast2600-evb
# with REAL init (/sbin/init) + networking. Sibling of the Cray XD670 box (same AMI SP-X platform).
#
# WHAT : full MegaRAC userland from the patched rootfs (RAM disk). /conf, /usr/local/www and /dre
#        mount from the ORIGINAL 64MB NOR image via mtdparts crafted so the mtdblock NUMBERS match
#        /etc/dupfstab (mtdblock1=conf, mtdblock3=www, mtdblock4=dre). Console on ttyS4.
# WHY  : promotes the unpacked ASMB-787 firmware into a live zoo denizen (Redfish + RMCP+ IPMI).
#
# KEY  : the firmware's /etc/dupfstab mounts by /dev/mtdblockN (by NUMBER, not name), so mtdparts
#        ORDER is what matters: uboot(0), conf(1)@0xd0000, bkupconf(2)@0x2d0000, www(3)@0x2810000,
#        dre(4)@0x2e10000 — each @offset lands exactly on the real jffs2/squashfs magic in the image.
# RUN  : BG=1 ./boot-asmb787-svc.sh   (background; console -> $WD/svc.log ; drive via $WD/cin)
# RELATED: qemu-patch-rootfs.sh (IPMIMain fixes), extract.sh, vbmc.box.
set -u
_HERE="$(cd "$(dirname "$0")" && pwd)"; _REPO="$(cd "$_HERE/../.." && pwd)"
WD="${WD:-$_REPO/work}"          # artifacts + console log + fifo (build.sh writes here)
IP="${IP:-127.0.0.1}"
HTTPS_PORT="${HTTPS_PORT:-6443}"; SSH_PORT="${SSH_PORT:-6022}"; IPMI_PORT="${IPMI_PORT:-6623}"

# mtdparts numbering MUST match /etc/dupfstab: mtdblock1=/conf, mtdblock3=/usr/local/www, mtdblock4=/dre.
MTDPARTS='mtdparts=1e620000.spi:832k@0(uboot),1984k@0xd0000(conf),1984k@0x2d0000(bkupconf),6144k@0x2810000(www),-@0x2e10000(dre)'
APPEND="console=ttyS4,115200n8 root=/dev/ram0 ro rootfstype=squashfs ramdisk_size=131072 ramdisk_blocksize=4096 $MTDPARTS maxcpus=1 rootwait"

# fresh pristine flash copy each boot so /conf starts clean -> IPMIMain auto-provisions default user.
cp -f "$WD/mtdflash.bin" "$WD/mtdflash-run.bin"
rm -f "$WD/asmb787-qmp.sock"
QEMU=(qemu-system-arm -M ast2600-evb -m 1024 -nographic
  -qmp "unix:$WD/asmb787-qmp.sock,server,nowait"
  -kernel "$WD/kernel.Image" -dtb "$WD/dtb-a1.dtb" -initrd "$WD/rootfs.sqfs"
  -drive "file=$WD/mtdflash-run.bin,format=raw,if=mtd"
  -net nic -net "user,hostfwd=tcp:$IP:$HTTPS_PORT-:443,hostfwd=tcp:$IP:$SSH_PORT-:22,hostfwd=udp:$IP:$IPMI_PORT-:623,hostname=asmb787bmc"
  -append "$APPEND")

if [ "${BG:-}" = 1 ]; then
  cd "$WD"; rm -f cin; mkfifo cin; : > svc.log
  ( tail -f cin ) | "${QEMU[@]}" > svc.log 2>&1 &
  echo "backgrounded. console -> $WD/svc.log ; send input: echo 'cmd' > $WD/cin"
else
  exec "${QEMU[@]}"
fi
