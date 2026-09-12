#!/usr/bin/env bash
# checksum-manifest.sh — regenerate firmware/manifest.txt from the files present in firmware/.
#
# Emits "<sha256>  <bytes>  <path>" per file, plus the tarballs' SHA-256. This is the reference
# list used to stage an external mirror and to verify downloads. Files missing from disk are
# listed as `?` for the size column (hash still shown when it is pinned in download-fw.sh).
#
# USAGE:  ./firmware/checksum-manifest.sh            # print to stdout
#         ./firmware/checksum-manifest.sh > firmware/manifest.txt
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/.." && pwd)"
cd "$ROOT"

sha() { shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }

# --- single-file images (sorted) ---
single=(
  encrypted_ASMB-787_20220912.ima_enc
  XD670_BMC_v1.27_signed.bin.hpm
  "iDRAC-with-Lifecycle-Controller_Firmware_92MM7_LN64_7.10.90.00_A00.BIN"
  "iDRAC-with-Lifecycle-Controller_Firmware_YP95X_LN64_1.30.10.50_A00.BIN"
  obmc-phosphor-image-gb200nvl-obmc.static.mtd
  evb-ast2600.static.mtd
  x14-flash.img
  x10-master.flash
  smc-x12-01.07.20.bin
  smc-x13-01.07.01.bin
  smc-x13d-01.08.08.bin
  smc-h13f-01.06.05.bin
  smc-h13s-01.09.16.bin
  fujitsu-irmc-s6.bin
)

# --- Supermicro X14 bundle (fetched directly by boxes/supermicro-x14/build.sh) ---
x14_bundle=(
  x14/svc-snap-full-working.gz
  x14/kernel.bin
  x14/x14-noncsi.dtb
  x14/initramfs-patched.bin
  x14/x14-ce0-64m.img
  x14/emmc.img
)

# --- tarballs (mirror packaging) ---
tarballs=(
  h3c-hdm3-2.06.02.tar.gz
  bluefield-bmc.tar.gz
  opengear-om2200-25.11.7.tar.gz
  lenovo-xcc2-1.10.tar.gz
)

emit() {
  local rel="$1"
  local abs="$ROOT/$rel"
  # Resolve symlinks (some firmware/ entries are symlinks into an external firmware store).
  local real="$abs"
  while [ -L "$real" ]; do real="$(readlink "$real")"; case "$real" in /*) ;; *) real="$(dirname "$abs")/$real";; esac; done
  if [ -f "$real" ]; then
    printf '%s  %s  %s\n' "$(sha "$real")" "$(stat -f '%z' "$real" 2>/dev/null || stat -c '%s' "$real")" "$rel"
  else
    # file not present — hash/size unknown here (size column `?`; hash from download-fw.sh).
    printf '%s  %s  %s\n' '????????????????????????????????????????????????????????????????' "?" "$rel"
  fi
}

cat <<'HEAD'
# zbmc reference firmware manifest
# ---------------------------------------------------------------------------
# Every firmware file the zbmc boxes need, with its SHA-256 and byte size.
# Use this to stage an external mirror (e.g. https://git.trouble.org/zbmc-lab/)
# and to verify downloads. Each line:  <sha256>  <bytes>  <path relative to this repo>
#
# Boxes fetch these via firmware/download-fw.sh (vendor URL first, mirror fallback).
# The mirror URL for a path is:  https://<mirror-host>/<path>
#
# Regenerate with:  firmware/checksum-manifest.sh
# ---------------------------------------------------------------------------

# --- single-file firmware images (firmware/) ---
HEAD
for f in "${single[@]}"; do emit "firmware/$f"; done

printf '\n# --- Supermicro X14 bundle (fetched directly by boxes/supermicro-x14/build.sh) ---\n'
for f in "${x14_bundle[@]}"; do emit "firmware/$f"; done

printf '\n# --- tarballs (unpack into firmware/<dir>/) ---\n'
for f in "${tarballs[@]}"; do emit "firmware/$f"; done
