#!/usr/bin/env bash
# restore-megarac-hpe.sh — restore a GREEN Cray XD670 BMC from a snapshot in ~10s (IPMI + Redfish live).
#
# WHAT: boots qemu -incoming from cray-snap.gz (made by snapshot-megarac-hpe.sh), re-attaching the matching
#       flash (cray-snap-flash.bin, copied to a fresh run file each time so restore is repeatable).
#       Comes up with IPMIMain already stable + admin/superuser provisioned — sidesteps the cold-boot
#       crash race entirely. Machine/kernel/dtb/net MUST match the snapshot exactly.
# USAGE: IP=10.0.6.66 WD=/Users/zen/phd/tmp/cray-xd670 ./restore-megarac-hpe.sh   (prints qemu pid)
#        Loopback dev: IP=127.0.0.1 HTTPS_PORT=8443 IPMI_PORT=8623 SSH_PORT=8022 ./restore-megarac-hpe.sh
set -u
WD="${WD:-/Users/zen/phd/tmp/cray-xd670}"
IP="${IP:-10.0.6.66}"
HTTPS_PORT="${HTTPS_PORT:-443}"; SSH_PORT="${SSH_PORT:-22}"; IPMI_PORT="${IPMI_PORT:-623}"
SNAP="${SNAP:-$WD/cray-snap.gz}"; SNAPFLASH="${SNAPFLASH:-$WD/cray-snap-flash.bin}"
[ -f "$SNAP" ] && [ -f "$SNAPFLASH" ] || { echo "no snapshot ($SNAP / $SNAPFLASH) — run snapshot-megarac-hpe.sh on a green boot first" >&2; exit 1; }
SUDO=; [ "$(id -u)" = 0 ] || SUDO=sudo
MTDPARTS='mtdparts=1e620000.spi:1M(uboot),2M(conf),2M(bkupconf),1M(extlog),4M(www),-(root)'
APPEND="console=ttyS4,115200n8 root=/dev/ram0 ro rootfstype=squashfs ramdisk_size=131072 ramdisk_blocksize=4096 $MTDPARTS rootwait"
# scope the kill to THIS box (hostname=megarac-hpe is in its hostfwd) — a bare
# '-M ast2600-evb' match nukes every ast2600 zoo box (x14, asmb787, evb, ...).
$SUDO pkill -9 -f 'hostname=megarac-hpe' 2>/dev/null || true; sleep 2
$SUDO rm -f "$WD/cray-qmp.sock" "$WD/cray.sock"
cp -f "$SNAPFLASH" "$WD/cray-restore-flash.bin"   # fresh writable copy -> repeatable restore
$SUDO qemu-system-arm -M ast2600-evb -m 1024 -display none -no-reboot \
  -serial "unix:$WD/cray.sock,server,nowait" -qmp "unix:$WD/cray-qmp.sock,server,nowait" \
  -incoming "exec:gunzip -c < $SNAP" \
  -kernel "$WD/kernel.Image" -dtb "$WD/dtb-a1.dtb" -initrd "$WD/rootfs.sqfs" \
  -drive "file=$WD/cray-restore-flash.bin,format=raw,if=mtd" \
  -net nic -net "user,hostfwd=tcp:$IP:$HTTPS_PORT-:443,hostfwd=tcp:$IP:$SSH_PORT-:22,hostfwd=udp:$IP:$IPMI_PORT-:623,hostfwd=tcp:$IP:${ASD_PORT:-5123}-:5123,hostname=megarac-hpe" \
  -append "$APPEND" >> "$WD/restore-console.log" 2>&1 &
QP=$!
disown $QP 2>/dev/null || true
echo "restore launched (pid $QP); IPMI/Redfish live in ~10s. Drive console: socat - UNIX-CONNECT:$WD/cray.sock"
