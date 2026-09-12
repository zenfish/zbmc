#!/usr/bin/env bash
# zbmc-lab:turnkey   <- iRMC S6 firmware fetched by firmware/download-fw.sh; builds the boot image.
#
# build.sh — carve + patch the Fujitsu iRMC S6 (AMI MegaRAC SP-X, AST2600) boot artifacts
# from the raw 56 MB NOR image (fetched into firmware/fujitsu-irmc-s6.bin). Steps 1-5: carve the
# zImage/root-squashfs/dtb, patch the dtb (single FMC chip, fixed-partitions, 128 MB video
# pool, reserved-memory carveouts), build the 64 MiB flash (0xFF pad + valid u-boot env),
# pad the rootfs to a 32 MiB SD image, and build the switch_root initramfs that neuters
# FTS_RedfishService. Boot is driven by the box's zbmc_boot (root-direct model).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
IMG="$ROOT/firmware/fujitsu-irmc-s6.bin"
BUILD="${1:-${WD:-$ROOT/work/fujitsu-irmc}}"

# Flash layout (from binwalk / FMH $MODULE$ parse of the RX2540M7 02.63S image):
KERNEL_UIMG=0x1fd0040   # osimage: uImage header; zImage payload at +0x40
ROOTFS_SQFS=0x130040    # root: raw squashfs (inside the uImage RAMDisk @0x130000)
DTB_OFF=0x110040        # dtb: AMI "AST2600 EVB" flattened device tree
SDR_OFF=0x23e0000       # platform: SDR/config squashfs (sdrcfg/libfts_sys.so, SDR.dat)
UBOOT_ENV=0x100000      # persistent u-boot env (0x10000); zeroed in the image -> CRC fails

[ -f "$IMG" ] || bash "$ROOT/firmware/download-fw.sh" fujitsu-irmc
[ -f "$IMG" ] || { echo "firmware image not found: $IMG" >&2; exit 1; }
for t in qemu-system-arm dtc python3 unsquashfs cpio gzip; do
  command -v "$t" >/dev/null || { echo "missing tool: $t" >&2; exit 1; }
done
mkdir -p "$BUILD"
cd "$BUILD"

# 1. Carve kernel (zImage), root squashfs (RAMdisk), and the AMI dtb
if [ ! -f kernel.bin ] || [ ! -f rootfs.sqsh ] || [ ! -f system.dtb ]; then
  echo "[build] carving kernel/rootfs/dtb"
  python3 - "$IMG" "$BUILD" "$KERNEL_UIMG" "$ROOTFS_SQFS" "$DTB_OFF" <<'PY'
import sys, struct
img, out = sys.argv[1], sys.argv[2]
koff, soff, doff = (int(sys.argv[i], 0) for i in (3, 4, 5))
d = open(img, 'rb').read()
assert d[koff:koff+4] == b'\x27\x05\x19\x56', "no uImage magic at kernel offset"
ksz = struct.unpack('>I', d[koff+12:koff+16])[0]
open(out+'/kernel.bin', 'wb').write(d[koff+64:koff+64+ksz]);  print("  kernel.bin  %d" % ksz)
assert d[soff:soff+4] == b'hsqs', "no squashfs magic at rootfs offset"
ssz = struct.unpack('<I', d[soff+0x28:soff+0x2c])[0]
open(out+'/rootfs.sqsh', 'wb').write(d[soff:soff+ssz]);       print("  rootfs.sqsh %d" % ssz)
assert struct.unpack('>I', d[doff:doff+4])[0] == 0xd00dfeed, "no FDT magic at dtb offset"
dsz = struct.unpack('>I', d[doff+4:doff+8])[0]
open(out+'/system.dtb', 'wb').write(d[doff:doff+dsz]);        print("  system.dtb  %d" % dsz)
PY
fi

# 2. Patch the dtb (five edits) -> system-patched.dtb
PATCH_VER=2
if [ ! -f system-patched.dtb ] || [ "$(cat .patch-ver 2>/dev/null)" != "$PATCH_VER" ]; then
  echo "[build] patching dtb"
  dtc -I dtb -O dts -o system.dts system.dtb 2>/dev/null
  python3 - system.dts system-patched.dts "$SDR_OFF" <<'PY'
import sys
src, dst, sdr = sys.argv[1], sys.argv[2], int(sys.argv[3], 0)
s = open(src).read()
# (a) disable FMC flash@1/flash@2 (qemu models one chip; mtd_concat NULL-derefs otherwise)
i = s.index('spi@1e620000 {'); d = 0; k = i
while k < len(s):
    if s[k] == '{': d += 1
    elif s[k] == '}':
        d -= 1
        if d == 0: end = k; break
    k += 1
fmc = s[i:end+1]
def disable(block, idx):
    j = block.index('flash@%d {' % idx); dd = 0; m = j
    while m < len(block):
        if block[m] == '{': dd += 1
        elif block[m] == '}':
            dd -= 1
            if dd == 0: e = m; break
        m += 1
    return block[:j] + block[j:e+1].replace('status = "okay";', 'status = "disabled";', 1) + block[e+1:]
fmc = disable(fmc, 1); fmc = disable(fmc, 2)
s = s[:i] + fmc + s[end+1:]
# (b) single-device mtd-concat
assert 'devices = <0x05 0x06 0x07>;' in s
s = s.replace('devices = <0x05 0x06 0x07>;', 'devices = <0x05>;', 1)
# (c) replace ami,spx-fmh with explicit fixed-partitions (platform SDR must mount)
old = 'compatible = "ami,spx-fmh";'
assert old in s
sdrhex = '0x%x' % sdr
new = ('compatible = "fixed-partitions";\n'
       '\t\t\t\t#address-cells = <0x01>;\n\t\t\t\t#size-cells = <0x01>;\n'
       '\t\t\t\tpartition@0 { label = "conf";     reg = <0x3800000 0x300000>; };\n'
       '\t\t\t\tpartition@1 { label = "bkupconf"; reg = <0x3b00000 0x100000>; };\n'
       '\t\t\t\tpartition@2 { label = "platform"; reg = <%s 0x40000>; read-only; };\n'
       '\t\t\t\tpartition@3 { label = "sdr";      reg = <%s 0x40000>; read-only; };\n'
       '\t\t\t\tpartition@4 { label = "iRMClog";  reg = <0x3c00000 0x100000>; };\n'
       '\t\t\t\tpartition@5 { label = "fru";      reg = <0x3ff0000 0x10000>; };' % (sdrhex, sdrhex))
s = s.replace(old, new, 1)
# (d) enlarge video framebuffer reserved-memory 16 MB -> 128 MB
assert 'size = <0x1000000>;' in s
s = s.replace('size = <0x1000000>;', 'size = <0x8000000>;', 1)
# (e) reserved-memory carveouts for AMI PERMDAT + host2bmc func1 shared-mem
i = s.index('reserved-memory {'); d = 0; k = i
while k < len(s):
    if s[k] == '{': d += 1
    elif s[k] == '}':
        d -= 1
        if d == 0: rend = k; break
    k += 1
ins = ('\t\tami_permdat@b7f20000 {\n\t\t\treg = <0xb7f20000 0x00100000>;\n\t\t\tno-map;\n\t\t};\n\n'
       '\t\tami_func1shm@b7fe0000 {\n\t\t\treg = <0xb7fe0000 0x00020000>;\n\t\t\tno-map;\n\t\t};\n\n\t')
s = s[:rend] + ins + s[rend:]
open(dst, 'w').write(s)
print("  patched: single FMC chip; fixed-partitions; 128 MB video pool; resmem carveouts")
PY
  dtc -I dts -O dtb -o system-patched.dtb system-patched.dts 2>/dev/null
  echo "$PATCH_VER" > .patch-ver
fi

# 3. Per-unit writable flash: pad to a 64 MiB chip (0xFF) + valid u-boot env
if [ ! -f flash64.img ] || [ "$IMG" -nt flash64.img ]; then
  echo "[build] building 64 MiB flash (0xFF pad + valid u-boot env)"
  python3 - "$IMG" flash64.img "$UBOOT_ENV" <<'PY'
import sys, binascii
d = bytearray(open(sys.argv[1], 'rb').read())
env_off = int(sys.argv[3], 0); ENV = 0x10000; SZ = 0x4000000
assert len(d) <= SZ
d += bytearray(b'\xff' * (SZ - len(d)))
pairs = [b"bootargs=console=ttyS4,115200n8 root=/dev/ram rw", b"bootcmd=bootfmh",
         b"bootdelay=2", b"baudrate=115200", b"autoload=no", b"verify=yes",
         b"spi_dma=no", b"do_memtest=0", b"bootselector=1", b"recentlyprogfw=1"]
data = b"\x00".join(pairs) + b"\x00\x00"
data = data + b"\x00" * (ENV - 4 - len(data))
crc = binascii.crc32(data) & 0xffffffff
d[env_off:env_off+ENV] = crc.to_bytes(4, 'little') + data
open(sys.argv[2], 'wb').write(d)
print("  flash64.img = 64 MiB; u-boot env crc=0x%08x" % crc)
PY
fi

# 4. Root squashfs as a power-of-2 SD image
if [ ! -f rootfs-sd.img ] || [ rootfs.sqsh -nt rootfs-sd.img ]; then
  echo "[build] padding root squashfs to a 32 MiB SD image"
  python3 - rootfs.sqsh rootfs-sd.img <<'PY'
import sys
d = open(sys.argv[1], 'rb').read(); SZ = 32*1024*1024
assert len(d) <= SZ, "rootfs squashfs > 32 MiB; bump SD size"
open(sys.argv[2], 'wb').write(d + b'\x00' * (SZ - len(d)))
print("  rootfs-sd.img = 32 MiB")
PY
fi

# 5. switch_root initramfs (vendor busybox) that neuters FTS_RedfishService
IRFS_VER=3
if [ ! -f initramfs.cpio.gz ] || [ "$(cat .irfs-ver 2>/dev/null)" != "$IRFS_VER" ] \
   || [ rootfs.sqsh -nt initramfs.cpio.gz ]; then
  echo "[build] building switch_root initramfs (busybox from the vendor rootfs)"
  rm -rf irfs sqx; mkdir -p irfs/{bin,lib,proc,sys,dev,newroot}
  unsquashfs -n -f -d sqx rootfs.sqsh bin/busybox 'lib/arm-linux-gnueabi/*' >/dev/null 2>&1 || true
  cp sqx/bin/busybox irfs/bin/busybox
  python3 - sqx/lib/arm-linux-gnueabi irfs/lib <<'PY'
import sys, os, struct, glob, shutil
srcdir, dst = sys.argv[1], sys.argv[2]
def soname(p):
    d = open(p, 'rb').read()
    if d[:4] != b'\x7fELF': return None
    sho = struct.unpack('<I', d[0x20:0x24])[0]; she = struct.unpack('<H', d[0x2e:0x30])[0]; shn = struct.unpack('<H', d[0x30:0x32])[0]
    secs = [struct.unpack('<IIIIIIIIII', d[sho+i*she:sho+i*she+40]) for i in range(shn)]
    dyn = [x for x in secs if x[1] == 6]
    if not dyn: return None
    dyn = dyn[0]; ds = secs[dyn[6]]; st = d[ds[4]:ds[4]+ds[5]]; o = dyn[4]
    while o < dyn[4]+dyn[5]:
        tag, val = struct.unpack('<iI', d[o:o+8]); o += 8
        if tag == 0: break
        if tag == 14:
            e = st.index(b'\x00', val); return st[val:e].decode()
    return None
for p in glob.glob(srcdir + '/*'):
    if os.path.isdir(p): continue
    b = os.path.basename(p); shutil.copy2(p, os.path.join(dst, b))
    sn = soname(p)
    if sn and sn != b and not os.path.exists(os.path.join(dst, sn)):
        try: os.symlink(b, os.path.join(dst, sn))
        except OSError: pass
if not os.path.exists(dst + '/ld-linux.so.3') and os.path.exists(dst + '/ld-2.28.so'):
    os.symlink('ld-2.28.so', dst + '/ld-linux.so.3')
print("  staged busybox + libs")
PY
  cat > irfs/init <<'INIT'
#!/bin/busybox sh
export PATH=/bin
busybox mkdir -p /proc /sys /dev /newroot
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys
busybox mount -t devtmpfs devtmpfs /dev
busybox mount -t squashfs -o ro /dev/mmcblk0 /newroot \
  || { busybox echo "[irmc-init] root squashfs mount FAILED"; exec busybox sh; }
if busybox grep -q irmc_no_redfish /proc/cmdline; then
  busybox printf '#!/bin/sh\nexit 0\n' > /noop; busybox chmod 0755 /noop
  busybox mount --bind /noop /newroot/usr/local/bin/FTS_RedfishService \
    && busybox echo "[irmc-init] FTS_RedfishService neutered"
fi
busybox mount --move /proc /newroot/proc
busybox mount --move /sys /newroot/sys
busybox mount --move /dev /newroot/dev
busybox echo "[irmc-init] switch_root -> /sbin/init"
exec busybox switch_root /newroot /sbin/init
INIT
  chmod +x irfs/init
  ( cd irfs && find . | cpio -o -H newc 2>/dev/null | gzip -1 ) > initramfs.cpio.gz
  echo "$IRFS_VER" > .irfs-ver
  echo "[build] initramfs.cpio.gz = $(wc -c < initramfs.cpio.gz) bytes"
fi

echo "[*] built iRMC S6 boot artifacts in $BUILD"
echo
echo "next:  ./tools/zbmc fujitsu-irmc start"
echo "       ./tools/zbmc fujitsu-irmc ipmi mc info   # admin / admin"
