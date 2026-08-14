#!/usr/bin/env bash
# run-p1.sh — Phase-1: boot iDRAC10 rootfs under QEMU npcm845-evb (AArch64 / NPCM845).
# WHAT   Minimal boot: kernel from md.itb + custom initramfs → mounts rootfs.squashfs → shell.
#        SELinux disabled via enforcing=0 (iDRAC10 ships enforcing; disabling for bring-up).
#        No networking (NIC emulation TBD — causes panics until IRQ mapping confirmed).
# GOAL   Phase 1 = console shell inside the iDRAC10 rootfs. That's it.
# RUN    ./extract-boot.sh   (once)
#        ./build-p1.sh       (once or after init changes)
#        ./run-p1.sh         (Ctrl-A X to quit)
# RELATED extract-boot.sh  build-p1.sh  RESUME-STATE.md  ../idrac9-vs-10/DIFFERENCES.html
set -euo pipefail; cd "$(dirname "$0")"

KERNEL=boot/Image
DTB=boot/idrac10.dtb
INITRD=boot/initramfs.p1.cpio.gz
SD=img/sd.img

for f in "$KERNEL" "$DTB" "$INITRD"; do
  [ -f "$f" ] || { echo "FATAL: $f missing — run extract-boot.sh + build-p1.sh first"; exit 1; }
done
[ -f "$SD" ] || echo "WARN: $SD missing — rootfs mount will fail (squashfs not attached)"

# append= = kernel cmdline
# enforcing=0     : disable SELinux enforcement (iDRAC10 ships enforcing/targeted; too noisy for bringup)
# console=ttyS0   : npcm845 UART0
# root=/dev/mmcblk0 : SD card block dev (squashfs attached as raw block device)
# rootfstype=squashfs : tell kernel type; initramfs init also tries mount explicitly
# init=/bin/sh    : skip systemd entirely in phase 1; drop straight to shell
#                   (change to /sbin/init to boot real systemd — expect unit failures)
APPEND="console=ttyS0,115200 enforcing=0 root=/dev/mmcblk0 rootfstype=squashfs ro init=/bin/sh"

SD_ARGS=()
if [ -f "$SD" ]; then
  SD_ARGS=(
    -drive "id=rootsd,if=none,file=$SD,format=raw,snapshot=on"
    -device sd-card,drive=rootsd,bus=sd-bus
  )
fi

SERIAL="${SERIAL_LOG:-}"
if [ -n "$SERIAL_LOG" ]; then
  SERIAL_ARG="-serial file:$SERIAL_LOG"
else
  SERIAL_ARG="-serial mon:stdio"
fi

exec qemu-system-aarch64 \
  -M npcm845-evb \
  -m 1G \
  -display none \
  -kernel "$KERNEL" \
  -dtb "$DTB" \
  -initrd "$INITRD" \
  -append "$APPEND" \
  "${SD_ARGS[@]}" \
  $SERIAL_ARG \
  "$@"
