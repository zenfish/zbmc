#!/usr/bin/env bash
# build.sh — regenerate the QEMU boot artifacts for the virtual ASMB-787 BMC from the firmware.
#
# WHAT : takes firmware/encrypted_ASMB-787_20220912.ima_enc and produces, in the work dir:
#          kernel.Image  dtb-a1.dtb  rootfs.sqfs  mtdflash.bin
#        These are what box/boot.sh (and zbmc.box) run. Kept OUT of git — regenerate here.
# WHY  : the firmware is the single source of truth; artifacts are ~104MB and fully derivable.
# HOW  : unpack-ami carves the FMH modules -> dumpimage pulls kernel+dtb from the FIT ->
#        the root squashfs is unsquashed, patched for qemu (qemu-patch-rootfs.sh), repacked ->
#        mtdflash = the raw 64MB NOR image (firmware truncated to the FMC chip size).
# RUN  : ./box/build.sh [WORKDIR]   (default WORKDIR = ~/phd/tmp/asmb787 or ./work)
# NEEDS: unsquashfs, mksquashfs (squashfs-tools), dumpimage (u-boot-tools), jefferson (pip),
#        python3, dtc (optional). tools/unpack-ami must be on PATH or alongside.
# zbmc:turnkey   <- this box builds + runs from a fresh clone (firmware ships in the repo)
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"          # boxes/advantech-asmb787 -> repo root
FW="$ROOT/firmware/encrypted_ASMB-787_20220912.ima_enc"
WD="${1:-${WD:-$ROOT/work/$(basename "$HERE")}}"       # -> work/advantech-asmb787/
UNPACK="$ROOT/tools/unpack-ami"

[ -f "$FW" ] || bash "$ROOT/firmware/download-fw.sh" advantech-asmb787   # fetch (vendor/mirror) if missing
[ -f "$FW" ] || { echo "firmware not found and fetch failed: $FW" >&2; exit 1; }
command -v unsquashfs >/dev/null || { echo "need squashfs-tools (unsquashfs/mksquashfs)"; exit 1; }
command -v dumpimage  >/dev/null || { echo "need u-boot-tools (dumpimage)"; exit 1; }
mkdir -p "$WD"; echo "[*] work dir: $WD"

# --- 1. unpack the firmware (carves FMH modules: squashfs root/www, jffs2 conf, FIT osimage) ------
UNP="$WD/unpacked"
echo "[*] unpacking firmware with unpack-ami"
bash "$UNPACK" "$FW" "$UNP" >/dev/null

# --- 2. kernel + dtb from the osimage FIT (qemu -kernel cannot unpack a FIT) -----------------------
FIT="$(ls "$UNP"/fw-fit/*.itb 2>/dev/null | while read -r f; do dumpimage -l "$f" 2>/dev/null | grep -qi 'Kernel Image' && { echo "$f"; break; }; done)"
[ -n "$FIT" ] || { echo "no FIT with a kernel found under $UNP/fw-fit" >&2; exit 1; }
echo "[*] kernel FIT: $(basename "$FIT")"
dumpimage -T flat_dt -p 0 -o "$WD/kernel.Image" "$FIT" >/dev/null   # image 0 = Linux kernel
dumpimage -T flat_dt -p 1 -o "$WD/dtb-a1.dtb"   "$FIT" >/dev/null   # image 1 = ast2600evb_a1 dtb

# --- 3. root filesystem: unsquash -> qemu patch -> repack ------------------------------------------
# pick the largest squashfs blob = the root fs (www is the smaller one)
RSQ="$(ls -S "$UNP"/fw-blobs/sqsh_*.sqsh 2>/dev/null | head -1)"
[ -n "$RSQ" ] || { echo "no squashfs blob under $UNP/fw-blobs" >&2; exit 1; }
echo "[*] root squashfs: $(basename "$RSQ")"
rm -rf "$WD/rootfs"
unsquashfs -f -d "$WD/rootfs" "$RSQ" >/dev/null
bash "$HERE/qemu-patch-rootfs.sh" "$WD/rootfs"          # IPMIMain fixes (see script header)
rm -f "$WD/rootfs.sqfs"
mksquashfs "$WD/rootfs" "$WD/rootfs.sqfs" -comp xz -b 131072 -all-root -noappend -quiet
rm -rf "$WD/rootfs"

# --- 4. NOR flash image = firmware truncated to the FMC chip size (w25q512jv = 64MiB exactly) ------
# qemu's m25p80 requires EXACTLY the modeled chip size; the .ima_enc is a few hundred bytes over 64MiB.
echo "[*] mtdflash.bin = firmware truncated to 64MiB"
cp -f "$FW" "$WD/mtdflash.bin"
{ command -v gtruncate >/dev/null && gtruncate -s 67108864 "$WD/mtdflash.bin"; } || truncate -s 67108864 "$WD/mtdflash.bin"

echo "[*] done. artifacts in $WD:"
for f in kernel.Image dtb-a1.dtb rootfs.sqfs mtdflash.bin; do
  printf '    %-14s %s bytes\n' "$f" "$(stat -f '%z' "$WD/$f" 2>/dev/null || stat -c '%s' "$WD/$f")"
done
echo
echo "next:  ./tools/zbmc advantech-asmb787 start     # boot it"
echo "       ./tools/zbmc advantech-asmb787 console   # log in (auto sysadmin/superuser)"
