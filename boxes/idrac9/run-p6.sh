#!/usr/bin/env bash
# run-p4.sh — Phase-6: systemd-managed mesh (multi-user) under QEMU (npcm750-evb).
# Boots straight to a custom mini.target (DefaultDependencies=no) — NO Dell 200-service
# cascade — to isolate and tear down the dbus-broker startup blocker. Console-only diagnostics
# (virt-debug.service dumps to /dev/console). No networking (EMC TX NULL-crashes the kernel;
# the mesh is local). Kernel: uImage.patched. DTB: p4 (GMAC off / EMC on / single-CPU).
# RUN: ./build-p4.sh then ./run-p4.sh   (Ctrl-A X to quit). Use --serial-log to tee console.
set -euo pipefail; cd "$(dirname "$0")"
DTB=boot/p4.dtb; [ -f "$DTB" ] || DTB=boot/p2uni.dtb
# QEMU_BIN: use ./qemu-system-arm-patched (migratable usb-net, for checkpoint-with-network) if set.
exec "${QEMU_BIN:-qemu-system-arm}" -M npcm750-evb -m 1G -display none \
  -kernel boot/uImage.patched -dtb "$DTB" -initrd boot/initramfs.p6.xz \
  -drive id=rootsd,if=none,file=img/sd256.img,format=raw,snapshot=on \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=udp::6623-:623,hostfwd=tcp::6443-:443 \
  -device usb-net,netdev=n1,bus=usb-bus.0,id=nic0 \
  -rtc base=2020-09-20T05:00:00,clock=vm \
  -qmp unix:/tmp/zbmc-idrac9-qmp.sock,server,nowait \
  -serial mon:stdio \
  -serial unix:/tmp/zbmc-idrac9-ttyS1.sock,server,nowait   # ttyS1 = interactive root shell (console-shell.service)
