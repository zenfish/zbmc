#!/usr/bin/env bash
# zbmc:turnkey   <- Dell iDRAC10 (NPCM845/aarch64). Fetches matched cold and warm artifacts.
#
# Bundle (mirror only — https://git.trouble.org/zbmc/idrac10/): patched kernel, gmac DTB, 256MB
# base SD image, warm checkpoint, and matching lab SSH key. The cfgdb defaults are generated from
# metadata inside that image.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/$(basename "$HERE")}}"
MIRROR="https://git.trouble.org/zbmc/idrac10"
mkdir -p "$WD"
sha() { shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }

# local-subdir:local-name:mirror-path:sha256
BUNDLE=(
"boot:Image.boot-patched:Image.boot-patched:f97fb270ed8043a6466b1a73e69abc67521cb626913c2624853bb56badcc9dc5"
"boot:qemu-gmac.dtb:qemu-gmac.dtb:da13910425999dc3e0ba4315ed1cf60b7f084f8baa787b647dfba9d718cd5fdc"
"img:sd.img:sd.img:d41d48602c603d48bb9fcc92f5802bce789e917fd9c049beb03d8fa3f7587efd"
"ckpt:state.gz:warm-20260831/state.gz:00aaf1b1d150d1fb410b6f5755c2950d5b0fbd07e1fba656e9f468d115256d2d"
"ckpt:overlay-frozen.qcow2:warm-20260831/overlay-frozen.qcow2:76b8da12ee5416b57d27dd3ac51081108ea4ba89264ccb853d53c1d107ffc426"
"ssh:operator:warm-20260831/operator:1598137b6fa1a5f0fcf07120fda34c47d9756eeca53689cb2680cb300522fbf2"
"ssh:operator.pub:warm-20260831/operator.pub:d192936295b0ae04c6a030c7c0efbba3653f2592829e2b5deb998b76ea0f3766"
)
for e in "${BUNDLE[@]}"; do
  IFS=: read -r sub f remote want <<<"$e"
  mkdir -p "$WD/$sub"
  out="$WD/$sub/$f"
  if [ -f "$out" ] && [ "$(sha "$out")" = "$want" ]; then echo "[*] $f ✓ present"; continue; fi
  echo "[*] fetching $f from mirror"
  tmp="$out.part.$$"
  trap 'rm -f "${tmp:-}"' EXIT
  curl -fL --retry 2 --connect-timeout 20 -o "$tmp" "$MIRROR/$remote"
  [ "$(sha "$tmp")" = "$want" ] || { echo "SHA-256 mismatch on $f" >&2; exit 1; }
  mv "$tmp" "$out"
  trap - EXIT
done

python3 "$HERE/build-cfgdb-defaults.py" "$WD/img/sd.img" "$WD/payload/cfgdb-defaults.sql"

chmod 600 "$WD/ssh/operator"
chmod 644 "$WD/ssh/operator.pub"

dtc -Wno-interrupts_property -@ -I dts -O dtb -o "$WD/qemu-usb-net.dtbo" \
  "$HERE/qemu-usb-net-overlay.dts"
fdtoverlay -i "$WD/boot/qemu-gmac.dtb" -o "$WD/qemu-usb-net.dtb" "$WD/qemu-usb-net.dtbo"

echo "[*] bundle ready in $WD"
echo "cold:  sudo ./tools/zbmc idrac10 start"
echo "warm:  sudo ./tools/zbmc idrac10 start --warm"
