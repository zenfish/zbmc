#!/usr/bin/env bash
# zbmc:turnkey - fetch the verified Lenovo XCC cold-boot artifact set.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/lenovo-xcc}}"
MIRROR=https://git.trouble.org/zbmc/lenovo-xcc

files=(
  'kernel.zImage|809502472131dc103f2be2d4445f1ca8521dfdb13adba0fb1180cb037b382eac'
  'xcc.dtb|5294f31c7ec783ac490358164d7cb8a91f8101c74eb3fc5b70a4a908fc83608f'
  'sram.bin|5de84970dc0cf63d8430ff03a713d8c95184b87e5e7dce688171e26d2f7cdd26'
  'ptables.bin|3f9cec954ad568c6e9970cf4a353bb41f4a2274cc288eb9434632d73734b581f'
  'emmc.qcow2|d228657d01262b741c72017764f8304570e1dbfb5c17145830842a248ed8c9d8'
)

mkdir -p "$WD"
for row in "${files[@]}"; do
  IFS='|' read -r file expected <<<"$row"
  if [ ! -f "$WD/$file" ] || [ "$(sha256sum "$WD/$file" | awk '{print $1}')" != "$expected" ]; then
    curl -fL --retry 2 -o "$WD/$file.part" "$MIRROR/$file?v=20260901"
    [ "$(sha256sum "$WD/$file.part" | awk '{print $1}')" = "$expected" ] || {
      echo "SHA-256 mismatch: $file" >&2
      exit 1
    }
    mv "$WD/$file.part" "$WD/$file"
  fi
done

printf 'source=Lenovo XCC 6.92 preserved Newyork-pass1 runtime\n' >"$WD/build-provenance.txt"
printf '%s\n' "${files[@]}" >>"$WD/build-provenance.txt"
echo "Lenovo XCC runtime ready in $WD"
