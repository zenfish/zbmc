#!/usr/bin/env bash
# run-p4.sh — Phase-4: minimal-systemd mesh bring-up under QEMU (npcm750-evb).
# Boots straight to a custom mini.target (DefaultDependencies=no) — NO Dell 200-service
# cascade — to isolate and tear down the dbus-broker startup blocker. Console-only diagnostics
# (virt-debug.service dumps to /dev/console). No networking (EMC TX NULL-crashes the kernel;
# the mesh is local). Kernel: uImage.patched. DTB: p4 (GMAC off / EMC on / single-CPU).
# RUN: ./build-p4.sh then ./run-p4.sh   (Ctrl-A X to quit). Use --serial-log to tee console.
set -euo pipefail; cd "$(dirname "$0")"
DTB=boot/p4.dtb; [ -f "$DTB" ] || DTB=boot/p2uni.dtb
exec qemu-system-arm -M npcm750-evb -m 1G -display none \
  -kernel boot/uImage.patched -dtb "$DTB" -initrd boot/initramfs.p4.xz \
  -drive id=rootsd,if=none,file=img/sd256.img,format=raw,snapshot=on \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=udp::6623-:623 \
  -device usb-net,netdev=n1,bus=usb-bus.0 \
  -serial mon:stdio
