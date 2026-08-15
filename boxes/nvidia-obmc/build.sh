#!/usr/bin/env bash
# vbmc-lab:turnkey   <- NVIDIA GB200NVL OpenBMC flash image; boots on stock qemu -M gb200nvl-bmc.
#
# build.sh — fetch (if missing) + stage the flash image into the box's work dir. Flash-boot: nothing to
# unpack, just copy the .mtd so boot.sh can run it (snapshot=on keeps the copy pristine).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
FW="$ROOT/firmware/obmc-phosphor-image-gb200nvl-obmc.static.mtd"
WD="${1:-${WD:-$ROOT/work/$(basename "$HERE")}}"

[ -f "$FW" ] || bash "$ROOT/firmware/download-fw.sh" nvidia-obmc   # fetch from mirror if missing
[ -f "$FW" ] || { echo "firmware not found and fetch failed: $FW" >&2; exit 1; }
mkdir -p "$WD"
cp -f "$FW" "$WD/flash.mtd"
echo "[*] staged $WD/flash.mtd ($(stat -f '%z' "$WD/flash.mtd" 2>/dev/null || stat -c '%s' "$WD/flash.mtd") bytes)"
echo
echo "next:  ./tools/vbmc nvidia-obmc start"
echo "       ./tools/vbmc nvidia-obmc ssh 'uname -a'          # root / 0penBmc"
echo "       ./tools/vbmc nvidia-obmc ipmi mc info            # + OEM NetFn 0x3C handlers"
