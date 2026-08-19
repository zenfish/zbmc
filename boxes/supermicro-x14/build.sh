#!/usr/bin/env bash
# zbmc-lab:turnkey   <- Supermicro X14 BMC (OpenBMC/AST2600). RESTORE-based: ships a warm snapshot
#                       captured in the scripted-daemon (qemu-x14-svc) mode, whose network survives -incoming.
#
# Bundle (mirror only — https://git.trouble.org/zbmc-lab/x14/): the direct-boot kernel + noncsi dtb +
# patched initramfs, the CE0 NOR image, the eMMC image (rootfs on mmcblk0), and the gzipped RAM state.
# PIN: restores only on the qemu it was captured with — qemu-system-arm 11.x.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/$(basename "$HERE")}}"
MIRROR="https://git.trouble.org/zbmc-lab/x14"
mkdir -p "$WD"
sha() { shasum -a256 "$1" 2>/dev/null | cut -d' ' -f1 || sha256sum "$1" | cut -d' ' -f1; }

BUNDLE=(
"svc-snap-full-working.gz:953b7c4f08303427e00c571f56bbf539fef1431f597190c585c3fad37556480f"
"kernel.bin:38f47d7c0d2d2b16ad4d9279d6e987d094d33e5943fb5fbf86ac3cac3b801063"
"x14-noncsi.dtb:a6fd7cbb73114c655f6414ee4ac9a971db1ea6d5fdfd6dc90525f055526e9653"
"initramfs-patched.bin:36ede3de2b4e77d2b98e707c359a0cdae477b89a952a76d79afd75257d169f40"
"x14-ce0-64m.img:226b8f842656cf2217092c79d473ec337874f98dfd3ca1d3c67244b66d17a17f"
"emmc.img:15a340d9a78a0a0619363ae1c6c952383918a15673f3226b37eff71a800fa4c1"
)
for e in "${BUNDLE[@]}"; do
  f="${e%%:*}"; want="${e##*:}"; out="$WD/$f"
  if [ -f "$out" ] && [ "$(sha "$out")" = "$want" ]; then echo "[*] $f ✓ present"; continue; fi
  echo "[*] fetching $f"
  curl -fL --retry 2 --connect-timeout 20 -o "$out" "$MIRROR/$f"
  [ "$(sha "$out")" = "$want" ] || { echo "SHA-256 mismatch on $f" >&2; exit 1; }
done
echo "[*] bundle ready in $WD"
echo "next:  ./tools/zbmc supermicro-x14 start ; ./tools/zbmc supermicro-x14 ssh 'uname -a'"
