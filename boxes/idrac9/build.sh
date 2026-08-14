#!/usr/bin/env bash
# build.sh — (re)build the virtual-iDRAC9 boot artifacts from the iDRAC9 firmware.
#
# WHAT : reconstructs boot/{md.itb,zImage,base.dtb}, the custom initramfs, and the
#        256 MiB SD image (rootfs.squashfs padded) from the extracted FIT firmware.
# WHY  : reproducibility — run.sh consumes these. Idempotent.
# TGT  : iDRAC9 firmimgFIT.d9, extracted at $FW below.
# RUN  : ./build.sh   (needs: dumpimage, dtc, xz, cpio, python3, truncate)
set -euo pipefail
cd "$(dirname "$0")"
FW=/Users/zen/phd/bmc/idrac9-firmware/extracted
ITB_TXT="$FW/images_md.itb@1.txt"          # hex-dump of the kernel ITB
SQUASH="$FW/images_rootfs.squashfs@1.data" # 177 MiB rootfs

mkdir -p boot img logs

echo "[1/5] reconstruct binary ITB from hex dump"
python3 - "$ITB_TXT" boot/md.itb <<'PY'
import sys,re
raw=open(sys.argv[1],'rb').read().decode('latin1')
hx=bytes.fromhex(''.join(re.findall(r'[0-9a-fA-F]{2}',raw)))
i=hx.find(bytes.fromhex('d00dfeed'))           # FIT magic
open(sys.argv[2],'wb').write(hx[i:])
PY

echo "[2/5] extract kernel / base DT from ITB"
dumpimage -T flat_dt -p 0 -o boot/zImage   boot/md.itb >/dev/null
dumpimage -T flat_dt -p 1 -o boot/base.dtb boot/md.itb >/dev/null

echo "[3/5] extract + customise initramfs"
rm -rf img/initrd && mkdir -p img/initrd
dumpimage -T flat_dt -p 2 -o boot/initramfs.cpio boot/md.itb >/dev/null
( cd img/initrd && xz -dc ../../boot/initramfs.cpio 2>/dev/null | cpio -idm 2>/dev/null )
cp init.custom img/initrd/init 2>/dev/null || {
  echo "  (init.custom missing — keeping repo copy of img/initrd/init)"; }
chmod +x img/initrd/init
( cd img/initrd && find . | cpio -o -H newc 2>/dev/null | xz --check=crc32 -c ) > boot/initramfs.custom.xz

echo "[4/5] build 256 MiB SD image (rootfs.squashfs padded to power-of-2)"
cp "$SQUASH" img/sd256.img
truncate -s 256M img/sd256.img

echo "[5/5] done. boot with ./run.sh"
ls -la boot/zImage boot/base.dtb boot/initramfs.custom.xz img/sd256.img
