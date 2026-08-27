#!/usr/bin/env bash
#
# restore-x14.sh — restore the virtual X14 BMC from the warm checkpoint (iDRAC10-style).
#
# WHAT:   Boots qemu with -incoming, loading ckpt/state.gz (a QMP-migrated RAM snapshot
#         of a fully-booted X14). Skips the slow/flaky ~10min cold boot entirely.
# WHY:    The vendor cold boot is nondeterministic under emulation (services spin on
#         absent hardware/secure-world). Snapshot one good boot, restore it forever.
# PREREQ: ckpt/state.gz exists (created by checkpoint.py against a good cold boot).
#         Raw disks (x14-ce0-64m.img, emmc.img) reused as-is — safe because the running
#         rootfs is a tmpfs overlay and the flash is read-only (no disk drift to capture).
# RUN:    QEMU=/path/to/qemu-system-arm ./restore-x14.sh   (reference launcher)
#
set -euo pipefail
cd "$(dirname "$0")"
IP="${ZBMC_IP:-10.0.8.14}"
STATE=ckpt/state.gz
[ -f "$STATE" ] || { echo "no checkpoint at $STATE — run a cold boot + checkpoint.py first"; exit 1; }
[ "$(uname -s)" = Linux ] || { echo "restore-x14.sh supports Linux only" >&2; exit 1; }
ip addr show dev lo | grep -qw "$IP" || sudo ip addr add "$IP/32" dev lo
sudo -n pkill -9 -f "hostname=x14bmc" 2>/dev/null || true; sleep 1

QEMU="${QEMU:-$(command -v qemu-system-arm || true)}"
[ -x "$QEMU" ] || { echo "set QEMU to an executable qemu-system-arm" >&2; exit 1; }
exec sudo "$QEMU" \
  -m 1024 -M ast2600-evb -nographic -no-reboot \
  -incoming "exec:gunzip -c < $STATE" \
  -kernel kernel.bin -dtb x14.dtb -initrd initramfs-patched.bin \
  -drive file=x14-ce0-64m.img,format=raw,if=mtd \
  -drive file=emmc.img,format=raw,if=sd,index=2 \
  -net nic -net user,hostfwd=tcp:$IP:${SSH_PORT:-22}-:22,hostfwd=tcp:$IP:${WEB_PORT:-443}-:443,hostfwd=udp:$IP:623-:623,hostname=x14bmc \
  -append "console=ttyS4,115200n8 root=/dev/ram rw maxcpus=1 initcall_blacklist=ast2600_spitee_init,optee_driver_init qemu-x14-ramroot"
