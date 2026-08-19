#!/usr/bin/env bash
# run-p6-restore.sh <state.gz> — restore a checkpointed virtual iDRAC9 from a saved machine-state file.
# Boots QEMU with -incoming (loads RAM+CPU+device state) instead of cold-booting (~15s vs ~15min).
#
# PATCHED-QEMU / NO-UNPLUG FLOW (current): with qemu-system-arm-patched (migratable usb-net, see
# qemu-patch/), ckpt.py does NOT unplug the NIC, so the saved state CONTAINS usb-net. This launcher
# must therefore be IDENTICAL to run-p6.sh (same usb-net cold-plug on usb-bus.0, NO usb-hub) plus
# -incoming. The VM starts PAUSED; run `ckpt.py restore-finish /tmp/zbmc-idrac9-qmp.sock` to cont
# (no device re-add needed — the NIC is already in the restored state, so network survives).
# Set QEMU_BIN=./qemu-system-arm-patched (REQUIRED to load a state saved by the patched binary).
#
# LEGACY (stock-qemu / unplug) state files (e.g. the 2026-07-06 img/ckpt/redfish-200-ready.gz) were
# saved WITHOUT usb-net but WITH a usb-hub vmstate; those load only with the old launcher variant
# (`-device usb-hub,bus=usb-bus.0,id=uhub`, no usb-net) + `ckpt.py restore-finish` re-adding nic0.
# See img/ckpt/RESTORE-README.md. A fresh gz saved with the patched qemu supersedes it.
# RUN: QEMU_BIN=./qemu-system-arm-patched ./run-p6-restore.sh img/ckpt/redfish-200-ready-net.gz
set -euo pipefail; cd "$(dirname "$0")"
STATE="${1:?usage: run-p6-restore.sh <state.gz>}"
[ -s "$STATE" ] || { echo "FATAL: state file '$STATE' missing/empty"; exit 1; }
DTB=boot/p4.dtb; [ -f "$DTB" ] || DTB=boot/p2uni.dtb
rm -f /tmp/zbmc-idrac9-qmp.sock
exec "${QEMU_BIN:-qemu-system-arm}" -M npcm750-evb -m 1G -display none \
  -kernel boot/uImage.patched -dtb "$DTB" -initrd boot/initramfs.p6.xz \
  -drive id=rootsd,if=none,file=img/sd256.img,format=raw,snapshot=on \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=udp::6623-:623,hostfwd=tcp::6443-:443 \
  -device usb-net,netdev=n1,bus=usb-bus.0,id=nic0 \
  -rtc base=2020-09-20T05:00:00,clock=vm \
  -qmp unix:/tmp/zbmc-idrac9-qmp.sock,server,nowait \
  -serial mon:stdio \
  -serial unix:/tmp/zbmc-idrac9-ttyS1.sock,server,nowait \
  -incoming "exec:gzip -dc < $STATE"
