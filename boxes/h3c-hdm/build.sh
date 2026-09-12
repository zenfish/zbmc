#!/usr/bin/env bash
# zbmc-lab:turnkey   <- H3C HDM3 firmware fetched by firmware/download-fw.sh; builds the boot image.
#
# build.sh — assemble a bootable 64 MiB AST2600 SPI flash image for H3C HDM3 from the
# SIGNHEAD sections (fetched into firmware/h3c-hdm3-2.06.02/sections/), and carve the
# kernel FIT (kernel/dtb/ramdisk) so we can boot direct-kernel with a custom cmdline.
# H3C's U-Boot force-builds bootargs from a CRC-packed env, so the -kernel path is the
# only clean way to add the systemd.mask/softlockup guards that keep the box from
# panic-rebooting under QEMU.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
SECT="$ROOT/firmware/h3c-hdm3-2.06.02/sections"
WD="${1:-${WD:-$ROOT/work/h3c-hdm}}"
OUT="$WD/hdm3-flash.img"

[ -f "$SECT/sectiontable.verify" ] || bash "$ROOT/firmware/download-fw.sh" h3c-hdm
[ -f "$SECT/sectiontable.verify" ] || { echo "sections not found: $SECT" >&2; exit 1; }
mkdir -p "$WD"

# --- 1. assemble the 64 MiB flash from the section offsets recorded in each header ---
if [ ! -f "$OUT" ]; then
  echo "[build] assembling 64 MiB flash from SIGNHEAD sections"
  dd if=/dev/zero of="$OUT" bs=1m count=64 2>/dev/null
  for name in uboot_spl uboot overlay_conf pfr kernel rootfs; do
    f="$SECT/$name.verify"
    [ -f "$f" ] || { echo "  (no $name.verify, skipping)"; continue; }
    off_hex=$(head -c 512 "$f" | tr -d '\0' | sed -n 's/.*"SECTION_OFFSET": *"\(0x[0-9A-Fa-f]*\)".*/\1/p' | head -1)
    [ -n "$off_hex" ] || { echo "  (no SECTION_OFFSET for $name, skipping)"; continue; }
    off=$((off_hex))
    tail -c +513 "$f" | dd of="$OUT" bs=65536 seek=$((off/65536)) conv=notrunc 2>/dev/null
    printf "  placed %-12s @ %-10s\n" "$name" "$off_hex"
  done
fi

# --- 2. carve the kernel FIT into kernel.bin / fdt.dtb / ramdisk.cpio -----------------
if [ ! -f "$WD/kernel.bin" ]; then
  echo "[build] carving kernel FIT"
  dd if="$SECT/kernel.verify" of="$WD/fit.itb" bs=512 skip=1 status=none
  python3 - "$WD/fit.itb" "$WD" <<'PY'
import sys, struct
fit, art = sys.argv[1], sys.argv[2]
b = open(fit, 'rb').read()
assert b[:4] == b'\xd0\x0d\xfe\xed', "not a FIT/DTB"
_, total, off_struct, off_strings, _, _, _, _, size_strings, size_struct = \
    struct.unpack('>10I', b[:40])
strings = b[off_strings:off_strings+size_strings]
def cstr(o):
    e = strings.index(b'\x00', o); return strings[o:e].decode()
p = off_struct; path = []; data = {}
FDT_BEGIN, FDT_END, FDT_PROP, FDT_NOP, FDT_ENDT = 1, 2, 3, 4, 9
while p < off_struct + size_struct:
    tag = struct.unpack('>I', b[p:p+4])[0]; p += 4
    if tag == FDT_BEGIN:
        e = b.index(b'\x00', p); name = b[p:e].decode(); p = e + 1
        p = (p + 3) & ~3; path.append(name)
    elif tag == FDT_END:
        path.pop()
    elif tag == FDT_PROP:
        plen, noff = struct.unpack('>II', b[p:p+8]); p += 8
        val = b[p:p+plen]; p = (p + plen + 3) & ~3
        if cstr(noff) == 'data' and len(path) >= 2 and path[-2] == 'images':
            data[path[-1]] = val
    elif tag in (FDT_NOP,):
        pass
    elif tag == FDT_ENDT:
        break
def pick(*prefs):
    for pre in prefs:
        for k, v in data.items():
            if k.startswith(pre): return v
    raise SystemExit("FIT subimage not found: " + str(prefs))
# kernel.bin, the default ramdisk, and fdt-base (skip the host-* variant dtbs)
open(art+'/kernel.bin','wb').write(pick('kernel'))
open(art+'/ramdisk.cpio','wb').write(pick('ramdisk'))
open(art+'/fdt.dtb','wb').write(pick('fdt-base','fdt'))
print("  kernel %d B, ramdisk %d B, dtb %d B" %
      (len(pick('kernel')), len(pick('ramdisk')), len(pick('fdt-base','fdt'))))
PY
  # patch the dtb: disable OP-TEE (qemu can't service the secure-world SMC calls)
  dtc -I dtb -O dts -o "$WD/fdt.dts" "$WD/fdt.dtb" 2>/dev/null
  python3 - "$WD/fdt.dts" "$WD/fdt-patched.dts" <<'PY'
import sys
s = open(sys.argv[1]).read()
if 'compatible = "linaro,optee-tz";' in s:
    s = s.replace('compatible = "linaro,optee-tz";\n\t\t\tmethod = "smc";',
                  'compatible = "linaro,optee-tz";\n\t\t\tmethod = "smc";\n\t\t\tstatus = "disabled";', 1)
open(sys.argv[2], 'w').write(s)
print("  patched dtb (optee disabled)")
PY
  dtc -I dts -O dtb -o "$WD/fdt-patched.dtb" "$WD/fdt-patched.dts" 2>/dev/null
fi

echo "[*] built $OUT + kernel.bin/fdt-patched.dtb/ramdisk.cpio in $WD"
echo
echo "next:  ./tools/zbmc h3c-hdm start"
echo "       ./tools/zbmc h3c-hdm ipmi mc info    # admin / Password@_"
