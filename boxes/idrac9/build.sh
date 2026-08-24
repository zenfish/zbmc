#!/usr/bin/env bash
# zbmc:turnkey   <- Dell iDRAC9 (NPCM750/ARM). COLD-BOOT based: fetches pre-built P4 boot
#                   artifacts from the mirror. "build" = fetch + verify SHA-256. The actual
#                   firmware extraction (from a Dell DUP) was done once; these are the results.
#
# Bundle (mirror only — https://git.trouble.org/zbmc/idrac9/): patched uImage + P4 dtb,
# P4 initramfs, 256MB SD image (rootfs squashfs), and the SSH key for root shell access.
# zbmc_boot() in zbmc.box does qemu-system-arm -M npcm750-evb cold boot.
# PIN: iDRAC9 firmware 7.10.90.00, P4 mesh boot (RAKP + IPMI + SSH).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/$(basename "$HERE")}}"
MIRROR="https://git.trouble.org/zbmc/idrac9"
sha() { shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }

# file : sha256
BUNDLE=(
"uImage.patched:6f0fbf30cca7b8d0b4a9715774718d79d2900daac141a1f4c94f00b6e7ebcad7"
"p4.dtb:59ce0d24b25739800a604824db1ea877e4d08b54f8ffa86c6b036bb4fc9024e8"
"initramfs.p4.xz:4d21d9d0409df2c16f61a9799ca5c9a22554c782e23cd95477785a14a185a6f8"
"sd256.img:8b9a9765d2806473f72051126c10d4ed8eb8c5d6b0b8c4dcfeba3387094fa094"
"vmkey:b4eee3bb6b863d529201f60c2e10e995a57905cd8a7266aa9dca569a959a3a0c"
)

mkdir -p "$WD/boot" "$WD/img"
for e in "${BUNDLE[@]}"; do
  f="${e%%:*}"; want="${e##*:}"
  # route files to the correct subdir
  case "$f" in sd256.img|vmkey) out="$WD/img/$f";; *) out="$WD/boot/$f";; esac
  if [ -f "$out" ] && [ "$(sha "$out")" = "$want" ]; then echo "[*] $f ✓ present"; continue; fi
  echo "[*] fetching $f from mirror"
  curl -fL --retry 2 --connect-timeout 20 -o "$out" "$MIRROR/$f"
  [ "$(sha "$out")" = "$want" ] || { echo "SHA-256 mismatch on $f" >&2; exit 1; }
done
chmod 600 "$WD/img/vmkey"

echo "[*] bundle ready in $WD"
echo "next:  ./tools/zbmc idrac9 start ; ./tools/zbmc idrac9 ipmi mc info"
