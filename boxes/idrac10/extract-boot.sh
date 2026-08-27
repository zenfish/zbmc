#!/usr/bin/env bash
# extract-boot.sh — extract kernel, DTB, and initramfs from iDRAC10 md.itb into boot/
# WHAT   Pulls the three boot components out of md.itb (the iDRAC10 FIT boot image) so
#        run-p1.sh can hand them directly to QEMU. iDRAC10 packs everything in md.itb:
#          Image 0 (fdt-1)      = base DTB (AArch64, 177KB)
#          Image 1 (kernel-1)   = Linux 6.12 kernel (gzip, 9.3MB compressed)
#          Image 3 (ramdisk-1)  = upstream initramfs (we replace this with our own)
# TARGET  qemu-system-aarch64 -M npcm845-evb
# NEEDS   dumpimage (u-boot-tools)
# RELATED run-p1.sh  build-p1.sh  RESUME-STATE.md
set -euo pipefail; cd "$(dirname "$0")"

# ── firmware location ──────────────────────────────────────────────────────────
# Run tools/unpack-idrac on the YP95X DUP first, then point this reference recipe at its output.
UNPACK="${IDRAC10_UNPACK:-}"
[ -n "$UNPACK" ] || { echo "FATAL: set IDRAC10_UNPACK to the unpacked YP95X directory" >&2; exit 1; }
BLOBS="$UNPACK/fw-fit-blobs"
MDITB="$BLOBS/md.itb"

[ -d "$BLOBS" ] || { echo "FATAL: fw-fit-blobs not found at $BLOBS"; exit 1; }
[ -f "$MDITB" ] || { echo "FATAL: md.itb not found at $MDITB"; exit 1; }

mkdir -p boot

echo "==> Extracting from $MDITB"
dumpimage -l "$MDITB" | head -40

# Image 0 = fdt-1 (base DTB)
echo "==> Image 0: base DTB → boot/idrac10.dtb"
dumpimage -T flat_dt -p 0 -o boot/idrac10.dtb "$MDITB"
file boot/idrac10.dtb

# Image 1 = kernel-1 (gzip AArch64)
echo "==> Image 1: kernel → boot/Image.gz"
dumpimage -T flat_dt -p 1 -o boot/Image.gz "$MDITB"
file boot/Image.gz
# QEMU aarch64 wants uncompressed Image or vmlinuz; decompress
gunzip -kf boot/Image.gz && echo "==> Decompressed → boot/Image" || true

# Image 3 = ramdisk-1 (Dell's initramfs — keep for reference, we replace with ours)
echo "==> Image 3: upstream initramfs → boot/initramfs.upstream"
dumpimage -T flat_dt -p 3 -o boot/initramfs.upstream "$MDITB" && echo "saved" || echo "(skipped — may need -T ramdisk)"

echo "==> Done. boot/ contents:"
ls -lh boot/
echo ""
echo "Next: ./build-p1.sh   then   ./run-p1.sh"
