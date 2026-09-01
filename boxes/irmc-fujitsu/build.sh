#!/usr/bin/env bash
# zbmc:turnkey - fetch the verified iRMC S6 cold-boot artifact set.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/irmc-fujitsu}}"
MIRROR=https://git.trouble.org/zbmc/irmc-fujitsu

files=(
  'kernel.bin|e139d58349922e59b763d5d1824e8fb60865524c206dda3b975769d5c4641df3'
  'system-patched.dtb|877bcd44fd590e800035ac221d386fc6908cb20ddcc575708ad1558bec758592'
  'initramfs.cpio.gz|aed0ce8eb706180b21e798acad707d26f2e7a9e5d8d6f5933ec3ad7f2f13ad14'
  'flash64.img|e029ad09372a37c400b30446701440f905a855042174d3222e542261acbb152c'
  'rootfs-sd.img|4b9cea861e4c71ce1d0c71d1b8692705e02305eda7eeba4cd322946ea9524d78'
)

mkdir -p "$WD"
for row in "${files[@]}"; do
  IFS='|' read -r file expected <<<"$row"
  if [ ! -f "$WD/$file" ] || [ "$(sha256sum "$WD/$file" | awk '{print $1}')" != "$expected" ]; then
    curl -fL --retry 2 -o "$WD/$file.part" "$MIRROR/$file"
    [ "$(sha256sum "$WD/$file.part" | awk '{print $1}')" = "$expected" ] || {
      echo "SHA-256 mismatch: $file" >&2
      exit 1
    }
    mv "$WD/$file.part" "$WD/$file"
  fi
done

printf 'source=Fujitsu iRMC S6 RX2540 M7 02.63S / SDR 03.67\n' >"$WD/build-provenance.txt"
printf 'source_flash_sha256=89dd885694ebc86af29e900f04e22d4b63998ac35055e18c86ba96d6016ce2ed\n' >>"$WD/build-provenance.txt"
printf '%s\n' "${files[@]}" >>"$WD/build-provenance.txt"
echo "Fujitsu iRMC S6 runtime ready in $WD"
