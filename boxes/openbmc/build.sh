#!/usr/bin/env bash
# zbmc:turnkey   <- vanilla OpenBMC flash image ships in this repo; boots on stock qemu ast2600-evb.
#
# build.sh — stage the OpenBMC flash image into the box's work dir. This is a "flash-boot" box: the
# .mtd already contains u-boot + kernel + rootfs, so there's nothing to unpack — build just copies the
# image so boot.sh can run it (with snapshot=on, so the copy stays pristine across boots).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
FW="$ROOT/firmware/evb-ast2600.static.mtd"
WD="${1:-${WD:-$ROOT/work/$(basename "$HERE")}}"

[ -f "$FW" ] || bash "$ROOT/firmware/download-fw.sh" openbmc   # fetch from mirror if missing
[ -f "$FW" ] || { echo "firmware not found and fetch failed: $FW" >&2; exit 1; }
mkdir -p "$WD"
cp -f "$FW" "$WD/flash.mtd"
echo "[*] staged $WD/flash.mtd ($(stat -f '%z' "$WD/flash.mtd" 2>/dev/null || stat -c '%s' "$WD/flash.mtd") bytes)"
echo
echo "next:  ./tools/zbmc openbmc start"
echo "       ./tools/zbmc openbmc ssh 'uname -a'      # root / 0penBmc"
echo "       ./tools/zbmc openbmc web                  # Redfish ServiceRoot"
