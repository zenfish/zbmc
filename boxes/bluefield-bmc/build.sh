#!/usr/bin/env bash
# zbmc-lab:turnkey   <- BF3 artifacts fetched by firmware/download-fw.sh; stages the boot image.
#
# build.sh — stage the BlueField-3 BMC boot artifacts (kernel.bin / fdt-boot.dtb /
# initramfs.cpio) into the box's work dir. The initramfs is a custom SPL-bypass build:
# BF3's own busybox+libs embedding the plaintext rootfs squashfs, loop-mounted into the
# real vendor systemd. Building it from scratch needs the extracted .bfb rootfs + FIT
# (the NVIDIA BF3 .bfb bundle); see docs/firmware-sources.md. The
# prebuilt artifacts are fetched from the project mirror by firmware/download-fw.sh.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/bluefield-bmc}}"
mkdir -p "$WD"

need=0
for f in kernel.bin fdt-boot.dtb initramfs.cpio; do
  [ -f "$WD/$f" ] || need=1
done
if [ "$need" = 1 ]; then
  bash "$ROOT/firmware/download-fw.sh" bluefield-bmc
  # download-fw.sh drops the staged artifacts into firmware/bluefield-bmc/; copy to work/.
  for f in kernel.bin fdt-boot.dtb initramfs.cpio; do
    [ -f "$WD/$f" ] || cp -f "$ROOT/firmware/bluefield-bmc/$f" "$WD/$f" 2>/dev/null || true
  done
fi
for f in kernel.bin fdt-boot.dtb initramfs.cpio; do
  [ -f "$WD/$f" ] || { echo "missing $WD/$f (fetch failed? see docs/firmware-sources.md)" >&2; exit 1; }
done
echo "[*] staged BF3 boot artifacts in $WD"
echo
echo "next:  ./tools/zbmc bluefield-bmc start"
echo "       ./tools/zbmc bluefield-bmc ipmi mc info   # root / 0penBmc, cipher 17"
