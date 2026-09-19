#!/usr/bin/env bash
# Build the QEMU boot artifacts directly from the HPE HPM.
#
# The .hpm is a PICMGFWU (HPM.1) wrapper
# around AMI FMH modules (NOT a linear flash), so we carve the kernel FIT + squashfs rootfs + the two
# JFFS2 /conf partitions at known offsets, pull kernel+dtb from the FIT (dumpimage), patch the rootfs for
# qemu, preserve the vendor firmware-info FMH, and reassemble a 64MB NOR with fixed partitions.
# OUT: work/megarac-hpe/{kernel.Image, dtb-a1.dtb, rootfs.sqfs, mtdflash.bin}
# NEEDS: dumpimage (u-boot-tools), fdtput (device-tree-compiler), squashfs-tools, python3.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
FW="${SRC:-$ROOT/firmware/XD670_BMC_v1.27_signed.bin.hpm}"
WD="${1:-${WD:-$ROOT/work/$(basename "$HERE")}}"
size() { stat -c '%s' "$1" 2>/dev/null || stat -f '%z' "$1"; }
sha() { sha256sum "$1" 2>/dev/null | cut -d' ' -f1 || shasum -a 256 "$1" | cut -d' ' -f1; }
BUILD_EPOCH=1775804692 # FW_BUILD_TIME=2026-04-10 07:04:52 UTC
FW_SHA256=4e85590c2d5f18caf670b916522555347173ac277b098713c889303a7630cb76

[ -f "$FW" ] || bash "$ROOT/firmware/download-fw.sh" megarac-hpe    # fetch from mirror if missing
[ -f "$FW" ] || { echo "firmware not found and fetch failed: $FW" >&2; exit 1; }
[ "$(sha "$FW")" = "$FW_SHA256" ] || { echo "SHA-256 mismatch on $FW" >&2; exit 1; }
mkdir -p "$WD"
WD="$(cd "$WD" && pwd)"
cd "$WD"

# offsets located by binwalk + d00dfeed/hsqs magic scan of this HPM (v1.27):
FIT_OFF=$((0x37502CF)); FIT_LEN=4716224          # kernel FIT (u-boot fitImage)
SQ_OFF=$((0x56028F));   SQ_LEN=52334577          # rootfs squashfs (xz)
C1_OFF=$((0x12028F));   C2_OFF=$((0x2C028F)); CONF_LEN=1572876   # JFFS2 /conf + /bkupconf
FWINFO_OFF=$((0x3EF028F)); FWINFO_LEN=$((0x140)) # firmware-info FMH used by /proc/ractrends/Helper/FwInfo

echo "[*] carving kernel FIT + squashfs + conf partitions from $(basename "$FW")"
# portable byte-carve via tail|head; head closing early SIGPIPEs tail, so relax pipefail here.
set +o pipefail
tail -c +$((FIT_OFF+1)) "$FW" | head -c $FIT_LEN  > kernel-fit.itb
tail -c +$((SQ_OFF+1))  "$FW" | head -c $SQ_LEN    > rootfs.sqfs
tail -c +$((C1_OFF+1))  "$FW" | head -c $CONF_LEN  > conf1.jffs2
tail -c +$((C2_OFF+1))  "$FW" | head -c $CONF_LEN  > conf2.jffs2
tail -c +$((FWINFO_OFF+1)) "$FW" | head -c $FWINFO_LEN > fwinfo.fmh
set -o pipefail

echo "[*] kernel Image + DTB from the FIT (qemu -kernel can't unpack a FIT)"
dumpimage -T flat_dt -p 0 -o kernel.Image kernel-fit.itb >/dev/null
dumpimage -T flat_dt -p 1 -o dtb-a1.dtb   kernel-fit.itb >/dev/null

echo "[*] replacing vendor FMH discovery with fixed partitions"
parts=/ahb/mtdconcat@0/partitions
fdtput -t s dtb-a1.dtb "$parts" compatible fixed-partitions
fdtput -t x dtb-a1.dtb "$parts" '#address-cells' 1
fdtput -t x dtb-a1.dtb "$parts" '#size-cells' 1
for spec in \
  "0 uboot 0 100000" \
  "100000 conf 100000 200000" \
  "300000 bkupconf 300000 200000" \
  "500000 extlog 500000 100000" \
  "600000 www 600000 400000" \
  "a00000 root a00000 3600000"; do
  set -- $spec
  part="$parts/partition@$1"
  fdtput -c dtb-a1.dtb "$part"
  fdtput -t s dtb-a1.dtb "$part" label "$2"
  fdtput -t x dtb-a1.dtb "$part" reg "$3" "$4"
done

echo "[*] patching rootfs for qemu (conf-seed + /conf/BMC symlink + disable hw-less IPMI ifcs)"
mv -f rootfs.sqfs rootfs.sqfs.orig
chmod -R u+rwX rootfs 2>/dev/null || true; rm -rf rootfs      # extracted tree has no-write dirs (crontabs)
unsquashfs -f -d rootfs rootfs.sqfs.orig >/dev/null
bash "$HERE/qemu-patch-rootfs.sh" rootfs
# The vendor crontab directory is mode 0644. Its owner can read it at runtime, but
# a non-root mksquashfs cannot traverse it to include the sysadmin crontab.
chmod u+x rootfs/etc/defconfig/crontabs
# Normalize only files changed after the vendor build; retain older vendor mtimes.
find rootfs -newermt "@$BUILD_EPOCH" -exec touch -h -d "@$BUILD_EPOCH" {} +
mksquashfs rootfs rootfs.sqfs -comp xz -b 131072 -all-root -noappend \
  -mkfs-time "$BUILD_EPOCH" -quiet
chmod -R u+rwX rootfs 2>/dev/null || true; rm -rf rootfs rootfs.sqfs.orig

echo "[*] building 64MB NOR image with NAMED mtd partitions (conf @1M, bkupconf @3M)"
python3 - <<'PY'
sz=64*1024*1024; f=bytearray(b'\xff'*sz)
def place(path, offset):
    data = open(path, 'rb').read()
    f[offset:offset+len(data)] = data
place('conf1.jffs2', 0x100000)
place('conf2.jffs2', 0x300000)
fwinfo = open('fwinfo.fmh', 'rb').read()
assert len(fwinfo) == 0x140
assert fwinfo.startswith(b'$MODULE$')
assert b'FW_CODEBASEVERSION=5.X\n' in fwinfo
f[0x3ef0000:0x3ef0000+len(fwinfo)] = fwinfo
open('mtdflash.bin','wb').write(f)
PY
rm -f kernel-fit.itb conf1.jffs2 conf2.jffs2 fwinfo.fmh

echo "[*] done. artifacts in $WD:"
for f in kernel.Image dtb-a1.dtb rootfs.sqfs mtdflash.bin; do
  printf '    %-14s %s bytes\n' "$f" "$(size "$WD/$f")"
done
echo
echo "next:  ./tools/zbmc megarac-hpe start ; ./tools/zbmc megarac-hpe ipmi mc info   (admin/superuser)"
