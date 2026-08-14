#!/usr/bin/env bash
# run-p2.sh — Phase-2: boot the real iDRAC9 userspace (systemd) under QEMU.
#
# STATUS (2026-06-22): boots the REAL stack — cfgdb, sshd keygen, oauth, iptables,
#   network, Dell power driver — NO crash, after three fixes found via gdb:
#     1. KERNEL PATCH: NOP dm_bufio's 30s cleanup-timer schedule (scripts/patch-kernel.py);
#        without it, __queue_work panics at ~31.8s on a corrupt per-cpu pwq.
#     2. SINGLE CPU (boot/p2uni.dtb, cpu@1 removed): the per-cpu pool_workqueue corruption
#        is CPU1-specific under qemu npcm750 — 1 logical CPU avoids ALL of it (dm_bufio, srcu...).
#     3. MASK Dell bail watchdogs (idrac-final / spi_failure / dell-earlyboot-bail@) that
#        deliberately `echo c > /proc/sysrq-trigger` when not in a real chassis.
#   Boot is SLOW under emulation (~0.4x real-time; several minutes to multi-user).
#   Kernel: uImage.patched (decompressed Image, dm_bufio NOP). DTB: p2uni (aes/sha/pl310/eth
#   disabled + single CPU). initrd: initramfs.p2.xz (custom /init = init.p2.custom).
# RUN : ./build.sh  (regenerates boot artifacts) then ./run-p2.sh   (Ctrl-A X to quit)
set -euo pipefail; cd "$(dirname "$0")"
exec qemu-system-arm -M npcm750-evb -m 1G -display none \
  -kernel boot/uImage.patched -dtb boot/p2uni.dtb -initrd boot/initramfs.p2.xz \
  -drive id=rootsd,if=none,file=img/sd256.img,format=raw,snapshot=on \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -serial mon:stdio
