#!/usr/bin/env bash
# zbmc-lab:turnkey   <- Dell iDRAC10 (NPCM845/aarch64). RESTORE-based: ships a warm snapshot, not a
#                       from-firmware build (cold boot is a dbus-broker socket-activation lottery under
#                       TCG; see docs/why-dell-is-hard.md). "build" = fetch the snapshot bundle + rebase.
#
# Bundle (mirror only — https://git.trouble.org/zbmc-lab/idrac10/): the patched kernel + gmac dtb, the
# 256MB base SD image, a frozen qcow2 overlay, and the gzipped RAM state. boot.sh does qemu -incoming.
# PIN: this snapshot restores only on the qemu it was captured with — qemu-system-aarch64 11.0.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/$(basename "$HERE")}}"
MIRROR="https://git.trouble.org/zbmc-lab/idrac10"
mkdir -p "$WD"
sha() { shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }

# file : sha256
BUNDLE=(
"Image.boot-patched:f97fb270ed8043a6466b1a73e69abc67521cb626913c2624853bb56badcc9dc5"
"qemu-gmac.dtb:da13910425999dc3e0ba4315ed1cf60b7f084f8baa787b647dfba9d718cd5fdc"
"sd.img:d41d48602c603d48bb9fcc92f5802bce789e917fd9c049beb03d8fa3f7587efd"
"overlay-frozen.qcow2:ad3e43efc0e4e2222859cdf7b6b40dc5a41fef42b0af9ab107a3f866f71bacbe"
"state.gz:78700e5cf6a4bec1ebb625a33dea469a8e06b0b4cc876a24e3000ddea6338a57"
)
for e in "${BUNDLE[@]}"; do
  f="${e%%:*}"; want="${e##*:}"; out="$WD/$f"
  if [ -f "$out" ] && [ "$(sha "$out")" = "$want" ]; then echo "[*] $f ✓ present"; continue; fi
  echo "[*] fetching $f from mirror"
  curl -fL --retry 2 --connect-timeout 20 -o "$out" "$MIRROR/$f"
  [ "$(sha "$out")" = "$want" ] || { echo "SHA-256 mismatch on $f" >&2; exit 1; }
done

# the overlay was captured with an absolute backing path; point it at OUR sd.img.
echo "[*] rebasing overlay onto $WD/sd.img"
qemu-img rebase -u -b "$WD/sd.img" -F raw "$WD/overlay-frozen.qcow2"

echo "[*] bundle ready in $WD"
echo "next:  ./tools/zbmc idrac10 start ; ./tools/zbmc idrac10 ipmi mc info"
