#!/usr/bin/env bash
# build-p1.sh — build Phase-1 initramfs: minimal busybox init → shell on console.
# WHAT   Packs a tiny initramfs (busybox sh + mount + a simple /init) that:
#          1. mounts the iDRAC10 rootfs.squashfs (from SD card) at /newroot
#          2. switch_root → /newroot with systemd as PID 1
#        Phase 1 goal = boot to a console shell. No networking, no services.
#        enforcing=0 on kernel cmdline disables SELinux enforcement.
# BUILD  ./build-p1.sh  (run after extract-boot.sh)
# RUN    ./run-p1.sh
# NEEDS  cpio, gzip, aarch64 busybox static binary
# RELATED extract-boot.sh  run-p1.sh  RESUME-STATE.md
set -euo pipefail; cd "$(dirname "$0")"

# ── source busybox aarch64 static ─────────────────────────────────────────────
# Grab from iDRAC10 rootfs squashfs if not overridden
UNPACK="${IDRAC10_UNPACK:-}"
ROOTFS="${IDRAC10_ROOTFS:-${UNPACK:+$UNPACK/fw-filesystems/rootfs}}"
BUSYBOX="${BUSYBOX:-${ROOTFS:+$ROOTFS/bin/busybox}}"
[ -f "$BUSYBOX" ] || { echo "FATAL: busybox not at $BUSYBOX — set BUSYBOX= or run unpack-idrac first"; exit 1; }
echo "==> using busybox: $BUSYBOX ($(file -b "$BUSYBOX" | cut -d, -f1))"

# ── build initramfs tree ───────────────────────────────────────────────────────
rm -rf img/initrd1 && mkdir -p img/initrd1/{bin,sbin,proc,sys,dev,mnt,newroot}
cp "$BUSYBOX" img/initrd1/bin/busybox
for cmd in sh mount switch_root mkdir ls cat dmesg; do
  ln -sf busybox "img/initrd1/bin/$cmd"
done

cat > img/initrd1/init <<'INITEOF'
#!/bin/sh
# Phase-1 init: mount essentials, mount rootfs squashfs, switch_root
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devtmpfs none /dev 2>/dev/null || mdev -s

# rootfs squashfs is the second partition on the SD card (or /dev/mmcblk0p2)
# Try common device paths for npcm845-evb SD card
for dev in /dev/mmcblk0 /dev/mmcblk0p1 /dev/sda /dev/vda; do
  if mount -t squashfs -o ro "$dev" /newroot 2>/dev/null; then
    echo "==> mounted squashfs from $dev"
    break
  fi
done

if [ -z "$(ls /newroot/bin 2>/dev/null)" ]; then
  echo "==> WARN: could not mount rootfs squashfs — dropping to shell"
  exec sh
fi

echo "==> switch_root to /newroot"
exec switch_root /newroot /sbin/init
INITEOF
chmod +x img/initrd1/init

echo "==> packing boot/initramfs.p1.cpio.gz"
_here="$PWD"
( cd img/initrd1 && find . | cpio -H newc -o 2>/dev/null | gzip > "$_here/boot/initramfs.p1.cpio.gz" )
echo "==> done: $(du -sh boot/initramfs.p1.cpio.gz)"

# ── SD card image: squashfs raw ────────────────────────────────────────────────
SQUASHFS="${IDRAC10_ROOTFS_SQ:-${UNPACK:+$UNPACK/fw-fit-blobs/rootfs.squashfs}}"
IMG=img/sd.img
if [ ! -f "$IMG" ] && [ -f "$SQUASHFS" ]; then
  echo "==> creating SD image from $SQUASHFS"
  cp "$SQUASHFS" "$IMG"
  echo "==> SD image: $(du -sh "$IMG")"
elif [ ! -f "$SQUASHFS" ]; then
  echo "WARN: rootfs.squashfs not found at $SQUASHFS — SD image not created"
  echo "      run unpack-idrac first, then re-run build-p1.sh"
fi

echo ""
echo "==> Build done. Run: ./run-p1.sh"
