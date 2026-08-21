#!/usr/bin/env bash
# extract.sh — regenerate the QEMU boot artifacts for the HPE Cray XD670 BMC from the HPM firmware.
#
# WHAT : carves the bootable pieces out of the AMI MegaRAC SP-X firmware update image and stages
#        them in the scratch workdir so boot-megarac-hpe.sh / boot-megarac-hpe-svc.sh can run them.
# WHY  : the .hpm is a PICMGFWU (HPM.1) wrapper around AMI FMH modules — NOT a linear flash image,
#        so you cannot just dd a flash and boot it. We pull the kernel FIT + squashfs rootfs + the
#        JFFS2 /conf partitions and reassemble a 64 MB NOR image with named MTD partitions.
# SoC  : Aspeed AST2600 (Cortex-A7) -> qemu 'ast2600-evb'.  Kernel = Linux 5.4.184-ami.
# SRC  : the BMC HPM shipped in the Cray XD670 component pack.
# OUT  : $WD/{kernel.Image, dtb-a1.dtb, rootfs.sqfs, mtdflash.bin}
# RUN  : ./extract.sh            (uses default SRC/WD below; override with env vars)
# NEEDS: dumpimage (u-boot-tools), unsquashfs, python3.  jefferson only if you want to browse /conf.
# RELATED: boot-megarac-hpe.sh (shell), boot-megarac-hpe-svc.sh (real init + net), zbmc.box, README.html.
set -euo pipefail

SRC="${SRC:-/Volumes/yyy/phd/bmc/HP/cray/SYSFW/BMC/XD670_BMC_v1.27_signed.bin.hpm}"
WD="${WD:-/Users/zen/phd/tmp/cray-xd670}"
mkdir -p "$WD"; cd "$WD"

[ -f "$SRC" ] || { echo "firmware not found: $SRC" >&2; exit 1; }

# --- offsets located by binwalk + 'd00dfeed' (FIT/DTB) magic scan of the HPM ------------------
# kernel FIT (u-boot fitImage): d00dfeed @ file 0x37502CF, totalsize 4716224
# squashfs rootfs (xz)        : 'hsqs'    @ file 0x56028F, image_size 52334577
# JFFS2 /conf + /bkupconf     :            @ file 0x12028F and 0x2C028F, 1572876 bytes each
FIT_OFF=$((0x37502CF)); FIT_LEN=4716224
SQ_OFF=$((0x56028F));   SQ_LEN=52334577
C1_OFF=$((0x12028F));   C2_OFF=$((0x2C028F)); CONF_LEN=1572876

echo "[*] carving kernel FIT + squashfs + conf partitions from $SRC"
dd if="$SRC" of=kernel-fit.itb bs=1 skip=$FIT_OFF count=$FIT_LEN status=none
dd if="$SRC" of=rootfs.sqfs    bs=1 skip=$SQ_OFF  count=$SQ_LEN  status=none
dd if="$SRC" of=conf1.jffs2    bs=1 skip=$C1_OFF  count=$CONF_LEN status=none
dd if="$SRC" of=conf2.jffs2    bs=1 skip=$C2_OFF  count=$CONF_LEN status=none

echo "[*] extracting raw kernel Image + default DTB from the FIT (qemu -kernel can't unpack a FIT)"
# image 0 = kernel@1 (Linux, load 0x80001000); the default fdt config is ast2600evb_a1 (index 1 here)
dumpimage -T flat_dt -p 0 -o kernel.Image kernel-fit.itb >/dev/null
dumpimage -T flat_dt -p 1 -o dtb-a1.dtb   kernel-fit.itb >/dev/null

echo "[*] patching rootfs for qemu (conf-seed + /conf/BMC symlink + disable hw-less IPMI ifcs)"
# Fixes the IPMIMain MsgHndlr SIGSEGV (RE 2026-07-28): IPMIMain reads literal /conf/BMC/IPMI.conf and
# spawns a MsgHndlr thread per enabled interface. See qemu-patch-rootfs.sh for the full RE + rationale.
# -all-root: unsquashfs loses root ownership on macOS, so force uid/gid 0 on repack.
PROJ="$(cd "$(dirname "$0")" && pwd)"
mv -f rootfs.sqfs rootfs.sqfs.orig            # the raw carved rootfs (untouched original)
chmod -R u+rwX rootfs 2>/dev/null; rm -rf rootfs
unsquashfs -f -d rootfs rootfs.sqfs.orig >/dev/null
bash "$PROJ/qemu-patch-rootfs.sh" rootfs
mksquashfs rootfs rootfs.sqfs -comp xz -b 131072 -all-root -noappend -quiet   # -> the rootfs we boot
chmod -R u+rwX rootfs 2>/dev/null; rm -rf rootfs rootfs.sqfs.orig

echo "[*] building 64 MB NOR image (FMC w25q512jv) with NAMED mtd partitions"
# mountall.sh finds /conf & /bkupconf by NAME in /proc/mtd, so the mtdparts= names on the kernel
# cmdline (see boot-megarac-hpe-svc.sh) MUST match this layout: conf @1M, bkupconf @3M.
python3 - <<PY
sz=64*1024*1024
f=bytearray(b'\xff'*sz)
def place(p,off):
    d=open(p,'rb').read(); f[off:off+len(d)]=d
place('conf1.jffs2',0x100000)   # -> mtd 'conf'     (2M slot @1M)
place('conf2.jffs2',0x300000)   # -> mtd 'bkupconf' (2M slot @3M)
open('mtdflash.bin','wb').write(f)
PY

echo "[*] done. artifacts in $WD:"
ls -l kernel.Image dtb-a1.dtb rootfs.sqfs mtdflash.bin
