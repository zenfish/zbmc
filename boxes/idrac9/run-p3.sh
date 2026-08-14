#!/usr/bin/env bash
# run-p3.sh — Phase-3 MINIMAL init: skip systemd + Dell's 200-service boot. Bring up only
#   networking + sshd + cfgdb (+ best-effort dbus/mesh/fullfw). Faster, no watchdog cascade.
# STATUS (2026-06-22): WORKS — full SSH root login into the emulated iDRAC9.
#   Boot this, then `./ssh-in.sh` for a root shell (uid=0, racadm present). Fixes:
#   - networking: npcm GMAC crashes on link-up (phylink_validate NULL-ptr, found via gdb);
#     use the EMC interface (eth2) instead -> ping gw 0%% loss, sshd reachable.
#   - cfgdb inits (tmpfs persistence layer); sshd binds :22; host keys -> tmpfs /etc/ssh.
#   - login: bind files-only /etc/nsswitch.conf (drop avct) -> root=/bin/sh + pubkey auth.
#   RAKP/racadm still need the full daemon mesh (dfserver/aim/cfgmgrd + dbus-no-systemd) -- next. Kernel: uImage.patched, DTB: p3 (single-CPU, eth enabled).
set -euo pipefail; cd "$(dirname "$0")"
exec qemu-system-arm -M npcm750-evb -m 1G -display none \
  -kernel boot/uImage.patched -dtb boot/p3.dtb -initrd boot/initramfs.p3.xz \
  -drive id=rootsd,if=none,file=img/sd256.img,format=raw,snapshot=on \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=udp::6623-:623 \
  -device usb-net,netdev=n1,bus=usb-bus.0 \
  -serial mon:stdio
