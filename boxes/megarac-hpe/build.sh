#!/usr/bin/env bash
# zbmc:turnkey   <- HPE XD670 BMC (AMI MegaRAC SP-X). Fetches cold-boot artifacts and a matched optional
#                   warm snapshot. Default start is cold; `start --warm` opts into the snapshot.
#
# Bundle (mirror only — https://git.trouble.org/zbmc/megarac-hpe/): the direct-boot kernel + dtb,
# patched rootfs, and clean 64MB NOR. The old warm state is intentionally excluded: its 0x17000-byte
# ASPEED SRAM block is incompatible with the current model's 0x18000-byte block.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/$(basename "$HERE")}}"
MIRROR="https://git.trouble.org/zbmc/megarac-hpe/cold-20260908"
mkdir -p "$WD"
sha() { shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }

BUNDLE=(
"kernel.Image:94843f212aaccfe311b34b874711ccbb387e5fe9d8a6caf4e3583bfbc18958e1"
"dtb-a1.dtb:57699dc066fd995075f234acd9b489461bda28a9e6f91b6b275363cb338b5939"
"rootfs.sqfs:d757b2ee0654c7a125e24316d2cfcb05f5919d0962a6901f71f1f0a9a9239b62"
"mtdflash.bin:d64412d0d0c13fc6bb03f52ea35bedf8762919a5c069c51a808e5e374b8e252e"
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
