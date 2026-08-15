#!/usr/bin/env bash
# (reference) build-from-HPM path — carves the DUP; the turnkey path is build.sh (warm-snap restore).
#
# build.sh — regenerate the QEMU boot artifacts from the BMC HPM. The .hpm is a PICMGFWU (HPM.1) wrapper
# around AMI FMH modules (NOT a linear flash), so we carve the kernel FIT + squashfs rootfs + the two
# JFFS2 /conf partitions at known offsets, pull kernel+dtb from the FIT (dumpimage), patch the rootfs for
# qemu (IPMIMain fixes), repack it, and reassemble a 64MB NOR image with NAMED mtd partitions.
# OUT: work/megarac-hpe/{kernel.Image, dtb-a1.dtb, rootfs.sqfs, mtdflash.bin}
# NEEDS: dumpimage (u-boot-tools), unsquashfs+mksquashfs (squashfs-tools), python3.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
FW="$ROOT/firmware/XD670_BMC_v1.27_signed.bin.hpm"
WD="${1:-${WD:-$ROOT/work/$(basename "$HERE")}}"

[ -f "$FW" ] || bash "$ROOT/firmware/download-fw.sh" megarac-hpe    # fetch from mirror if missing
[ -f "$FW" ] || { echo "firmware not found and fetch failed: $FW" >&2; exit 1; }
mkdir -p "$WD"; cd "$WD"

# offsets located by binwalk + d00dfeed/hsqs magic scan of this HPM (v1.27):
FIT_OFF=$((0x37502CF)); FIT_LEN=4716224          # kernel FIT (u-boot fitImage)
SQ_OFF=$((0x56028F));   SQ_LEN=52334577          # rootfs squashfs (xz)
C1_OFF=$((0x12028F));   C2_OFF=$((0x2C028F)); CONF_LEN=1572876   # JFFS2 /conf + /bkupconf

echo "[*] carving kernel FIT + squashfs + conf partitions from $(basename "$FW")"
# portable byte-carve via tail|head; head closing early SIGPIPEs tail, so relax pipefail here.
set +o pipefail
tail -c +$((FIT_OFF+1)) "$FW" | head -c $FIT_LEN  > kernel-fit.itb
tail -c +$((SQ_OFF+1))  "$FW" | head -c $SQ_LEN    > rootfs.sqfs
tail -c +$((C1_OFF+1))  "$FW" | head -c $CONF_LEN  > conf1.jffs2
tail -c +$((C2_OFF+1))  "$FW" | head -c $CONF_LEN  > conf2.jffs2
set -o pipefail

echo "[*] kernel Image + DTB from the FIT (qemu -kernel can't unpack a FIT)"
dumpimage -T flat_dt -p 0 -o kernel.Image kernel-fit.itb >/dev/null
dumpimage -T flat_dt -p 1 -o dtb-a1.dtb   kernel-fit.itb >/dev/null

echo "[*] patching rootfs for qemu (conf-seed + /conf/BMC symlink + disable hw-less IPMI ifcs)"
mv -f rootfs.sqfs rootfs.sqfs.orig
chmod -R u+rwX rootfs 2>/dev/null || true; rm -rf rootfs      # extracted tree has no-write dirs (crontabs)
unsquashfs -f -d rootfs rootfs.sqfs.orig >/dev/null
bash "$HERE/qemu-patch-rootfs.sh" rootfs
mksquashfs rootfs rootfs.sqfs -comp xz -b 131072 -all-root -noappend -quiet
chmod -R u+rwX rootfs 2>/dev/null || true; rm -rf rootfs rootfs.sqfs.orig

echo "[*] building 64MB NOR image with NAMED mtd partitions (conf @1M, bkupconf @3M)"
python3 - <<PY
sz=64*1024*1024; f=bytearray(b'\xff'*sz)
def place(p,off):
    d=open(p,'rb').read(); f[off:off+len(d)]=d
place('conf1.jffs2',0x100000); place('conf2.jffs2',0x300000)
open('mtdflash.bin','wb').write(f)
PY
rm -f kernel-fit.itb conf1.jffs2 conf2.jffs2

echo "[*] done. artifacts in $WD:"
for f in kernel.Image dtb-a1.dtb rootfs.sqfs mtdflash.bin; do
  printf '    %-14s %s bytes\n' "$f" "$(stat -f '%z' "$WD/$f" 2>/dev/null || stat -c '%s' "$WD/$f")"
done
echo
echo "next:  ./tools/vbmc megarac-hpe start ; ./tools/vbmc megarac-hpe ipmi mc info   (admin/superuser)"
