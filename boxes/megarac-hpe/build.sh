#!/usr/bin/env bash
# zbmc:turnkey   <- HPE XD670 BMC (AMI MegaRAC SP-X). Fetches cold-boot artifacts and a matched optional
#                   warm snapshot. Default start is cold; `start --warm` opts into the snapshot.
#
# Bundle (mirror only — https://git.trouble.org/zbmc/megarac-hpe/): the direct-boot kernel + dtb +
# patched rootfs, the frozen 64MB NOR (flash at snapshot time), and the gzipped RAM state. Pinned to
# qemu-system-arm 11.x. The kernel/dtb/rootfs here are the SNAPSHOT's exact copies (must match the RAM state).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/$(basename "$HERE")}}"
MIRROR="https://git.trouble.org/zbmc/megarac-hpe"
mkdir -p "$WD"
sha() { shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }

BUNDLE=(
"kernel.Image:94843f212aaccfe311b34b874711ccbb387e5fe9d8a6caf4e3583bfbc18958e1"
"dtb-a1.dtb:93438c81541114fff9466eeb6749dea17a791648b7824c4d9f80be549bdf020f"
"rootfs.sqfs:cc1e943e8719c0a86a80c9a187f45f5fa8b9df9f9fe5ad99b0c2b5129a843bc2"
"cray-snap-flash.bin:fee909f2b9ff4ed4f1004fdd542b43419c5c30661dbf42e56020f44d64d81a54"
"cray-snap.gz:96db71cea52f5a46664eff6ecdb73b9cb254b9cc49d7e26fd6645b9101de662a"
)
for e in "${BUNDLE[@]}"; do
  f="${e%%:*}"; want="${e##*:}"; out="$WD/$f"
  if [ -f "$out" ] && [ "$(sha "$out")" = "$want" ]; then echo "[*] $f ✓ present"; continue; fi
  echo "[*] fetching $f"
  curl -fL --retry 2 --connect-timeout 20 -o "$out" "$MIRROR/$f"
  [ "$(sha "$out")" = "$want" ] || { echo "SHA-256 mismatch on $f" >&2; exit 1; }
done
echo "[*] bundle ready in $WD"
echo "next:  ./tools/zbmc megarac-hpe start ; ./tools/zbmc megarac-hpe ipmi mc info   (admin/superuser)"
