#!/usr/bin/env bash
# zbmc:turnkey   <- Dell iDRAC10 (NPCM845/aarch64). Fetches the cold-boot artifacts and generates
#                   an installation-specific SSH operator key.
#
# Bundle (mirror only — https://git.trouble.org/zbmc/idrac10/): patched kernel, gmac DTB, 256MB
# base SD image. The cfgdb defaults are generated from metadata inside that image.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/$(basename "$HERE")}}"
MIRROR="https://git.trouble.org/zbmc/idrac10"
mkdir -p "$WD"
sha() { shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }

# file : sha256
# subdir:file:sha256
BUNDLE=(
"boot:Image.boot-patched:f97fb270ed8043a6466b1a73e69abc67521cb626913c2624853bb56badcc9dc5"
"boot:qemu-gmac.dtb:da13910425999dc3e0ba4315ed1cf60b7f084f8baa787b647dfba9d718cd5fdc"
"img:sd.img:d41d48602c603d48bb9fcc92f5802bce789e917fd9c049beb03d8fa3f7587efd"
)
for e in "${BUNDLE[@]}"; do
  sub="${e%%:*}"; rest="${e#*:}"; f="${rest%%:*}"; want="${rest##*:}"
  mkdir -p "$WD/$sub"
  out="$WD/$sub/$f"
  if [ -f "$out" ] && [ "$(sha "$out")" = "$want" ]; then echo "[*] $f ✓ present"; continue; fi
  echo "[*] fetching $f from mirror"
  curl -fL --retry 2 --connect-timeout 20 -o "$out" "$MIRROR/$f"
  [ "$(sha "$out")" = "$want" ] || { echo "SHA-256 mismatch on $f" >&2; exit 1; }
done

python3 "$HERE/build-cfgdb-defaults.py" "$WD/img/sd.img" "$WD/payload/cfgdb-defaults.sql"

if [ ! -f "$WD/ssh/operator" ]; then
  mkdir -p "$WD/ssh"
  ssh-keygen -q -t ed25519 -N '' -C 'zbmc idrac10 operator' -f "$WD/ssh/operator"
fi
chmod 600 "$WD/ssh/operator"
chmod 644 "$WD/ssh/operator.pub"

echo "[*] bundle ready in $WD"
echo "next:  ./tools/zbmc idrac10 start ; ./tools/zbmc idrac10 ipmi mc info"
