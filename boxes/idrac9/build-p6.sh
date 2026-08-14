#!/usr/bin/env bash
# build-p4.sh — repack the Phase-6 initramfs (boot/initramfs.p6.xz) from init.p6.custom.
# Phase 4 = minimal-systemd mesh bring-up (mini.target, DefaultDependencies=no) used to tear
# down the dbus-broker -131 blocker. Reuses the patched kernel + p4.dtb already in boot/.
# Substitutes the VM pubkey (img/vmkey.pub) into the __PUBKEY__ placeholder.
# RUN: ./build-p4.sh   then   ./run-p4.sh
set -euo pipefail; cd "$(dirname "$0")"
[ -d img/initrd ] || { echo "FATAL: img/initrd (base initramfs) missing — run build.sh first"; exit 1; }
PUB="$(cat img/vmkey.pub)"
rm -rf img/initrd6 && cp -a img/initrd img/initrd6
sed "s|__PUBKEY__|$PUB|" init.p6.custom > img/initrd6/init
chmod +x img/initrd6/init
(cd img/initrd6 && find . | cpio -o -H newc 2>/dev/null | xz --check=crc32 -c) > boot/initramfs.p6.xz
echo "built boot/initramfs.p6.xz ($(wc -c < boot/initramfs.p6.xz) bytes)"
