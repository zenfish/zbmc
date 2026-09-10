#!/usr/bin/env bash
#
# restore-svc-x14.sh — restore the SVC-mode virtual X14 from a snapshot in ~10s, network live.
#
# WHAT:  Boots qemu -incoming from a snapshot made by snapshot-x14.sh. Comes up with the SVC
#        daemon stack already running and a WORKING network (verified UDP 623 + TCP 443).
# WHY:   Fast-retry base for iterating bmcweb/daemon bringup without a full cold boot each time.
# USAGE: restore-svc-x14.sh [snapfile]   (default: svc-snap.gz).  Drive via socat serial.sock.
# NOTE:  Must match the snapshot's machine/dtb exactly (ast2600-evb + x14-noncsi.dtb).
#
set -euo pipefail
cd "${WD:-$(dirname "$0")}"
SNAP="${1:-svc-snap.gz}"; IP="${ZBMC_IP:-10.0.8.14}"
TAP="${TAP:-ztap-x14}"; MAC="${MAC:-52:54:00:fa:00:21}"
CONSOLE_LOG="${ZBMC_CONSOLE_LOG:-console-uart.log}"
[ -f "$SNAP" ] || { echo "no snapshot at $SNAP — run snapshot-x14.sh first"; exit 1; }
sudo -n pkill -9 -f "ifname=$TAP" 2>/dev/null || true; sleep 2
sudo -n rm -f serial.sock qmp.sock
QEMU="${QEMU:-$(command -v qemu-system-arm)}"
sudo -n "$QEMU" \
  -m 1024 -M ast2600-evb -display none -no-reboot \
  -chardev "socket,id=serial0,path=serial.sock,server=on,wait=off,logfile=$CONSOLE_LOG,logappend=off" \
  -serial chardev:serial0 -qmp unix:qmp.sock,server,nowait \
  -incoming "exec:gunzip -c < $SNAP" \
  -kernel kernel.bin -dtb x14-noncsi.dtb -initrd initramfs-patched.bin \
  -drive file=x14-ce0-64m.img,format=raw,if=mtd,snapshot=on -drive file=emmc.img,format=raw,if=sd,index=2,snapshot=on \
  -netdev "tap,id=bmcnet,ifname=$TAP,script=no,downscript=no" \
  -net "nic,netdev=bmcnet,macaddr=$MAC" \
  -append "console=ttyS4,115200n8 root=/dev/ram rw maxcpus=1 initcall_blacklist=ast2600_spitee_init,optee_driver_init qemu-x14-ramroot qemu-x14-svc loglevel=4" \
  >console.log 2>&1 &   # redirect: else qemu holds caller's stdout -> caller hangs
echo "restore launched (pid $!); network live in ~10s. socat serial.sock to drive."
disown 2>/dev/null || true
