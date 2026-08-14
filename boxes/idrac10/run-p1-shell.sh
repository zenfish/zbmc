#!/usr/bin/env bash
# run-p1-shell.sh — Working Phase 1 boot: iDRAC10 Linux 6.12.40 shell via socket
# WHAT   Boots iDRAC10 AArch64 kernel (NPCM845) under qemu npcm845-evb.
#        Mounts squashfs rootfs from sd.img. Drops to /usr/bin/sh as PID 1.
#        Serial on UNIX socket (or stdio with INTERACTIVE=1).
# HOW    Serial = unix socket; connect: socat - UNIX-CONNECT:/tmp/idrac10.sock
# PATCHES APPLIED TO KERNEL BINARY (Image.boot-patched):
#   1. WFE→NOP at 0xc29164 (prevent hang on WFE in QEMU without WFI emul)
#   2. loglevel=0→8 + remove 'quiet' in compiled-in DTB (was suppressing ALL output)
#   3. blkdevparts=... replaced with root=/dev/mmcblk0 rootfstype=squashfs ro init=/usr/bin/sh
# DTB (qemu-sdhc.dtb): minimal DT with ns16550a UART0 + nuvoton,npcm845-sdhci + GIC + timer
set -euo pipefail; cd "$(dirname "$0")"

SOCK=/tmp/idrac10.sock
[ -S "$SOCK" ] && rm -f "$SOCK"

SERIAL_ARG="-serial unix:${SOCK},server,nowait"
[ "${INTERACTIVE:-0}" = "1" ] && SERIAL_ARG="-serial mon:stdio"

exec qemu-system-aarch64 \
  -M npcm845-evb -m 1G \
  -kernel boot/Image.boot-patched \
  -dtb boot/qemu-sdhc.dtb \
  -drive "id=rootsd,if=none,file=img/sd.img,format=raw,snapshot=on" \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -display none \
  $SERIAL_ARG \
  "$@"
