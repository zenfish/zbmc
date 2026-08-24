#!/usr/bin/env bash
#
# restore-svc-x14.sh — restore the SVC-mode virtual X14 from a snapshot in ~10s, network live.
#
# WHAT:  Boots qemu -incoming from a snapshot made by snapshot-x14.sh. Comes up with the SVC
#        daemon stack already running and a WORKING network (verified UDP 623 + TCP 443).
# WHY:   Fast-retry base for iterating bmcweb/daemon bringup without a full cold boot each time.
# USAGE: restore-svc-x14.sh [snapfile]   (default: svc-snap.gz).  Drive via socat /tmp/x14.sock.
# NOTE:  Must match the snapshot's machine/dtb exactly (ast2600-evb + x14-noncsi.dtb).
#
set -euo pipefail
cd "${WD:-$(dirname "$0")}"
SNAP="${1:-svc-snap.gz}"; IP="${ZBMC_IP:-10.0.8.14}"
[ -f "$SNAP" ] || { echo "no snapshot at $SNAP — run snapshot-x14.sh first"; exit 1; }
case "$(uname -s)" in Darwin) ifconfig lo0 | grep -q "$IP" || sudo ifconfig lo0 alias "$IP";; *) ip addr show dev lo | grep -q "$IP" || sudo ip addr add "$IP/32" dev lo;; esac
sudo -n pkill -9 -f "hostname=x14bmc" 2>/dev/null || true; sleep 2
sudo -n rm -f /tmp/x14.sock /tmp/x14-qmp.sock
QEMU="${QEMU:-$(command -v qemu-system-arm || echo /opt/homebrew/bin/qemu-system-arm)}"
sudo -n "$QEMU" \
  -m 1024 -M ast2600-evb -display none -no-reboot \
  -serial unix:/tmp/x14.sock,server,nowait -qmp unix:/tmp/x14-qmp.sock,server,nowait \
  -incoming "exec:gunzip -c < $SNAP" \
  -kernel kernel.bin -dtb x14-noncsi.dtb -initrd initramfs-patched.bin \
  -drive file=x14-ce0-64m.img,format=raw,if=mtd -drive file=emmc.img,format=raw,if=sd,index=2 \
  -net nic -net user,hostfwd=tcp:$IP:${SSH_PORT:-22}-:22,hostfwd=tcp:$IP:${WEB_PORT:-443}-:443,hostfwd=udp:$IP:623-:623,hostname=x14bmc \
  -append "console=ttyS4,115200n8 root=/dev/ram rw maxcpus=1 initcall_blacklist=ast2600_spitee_init,optee_driver_init qemu-x14-ramroot qemu-x14-svc loglevel=4" \
  >/tmp/x14-restore-console.log 2>&1 &   # redirect: else qemu holds caller's stdout -> caller hangs
echo "restore launched (pid $!); network live in ~10s. socat /tmp/x14.sock to drive."
disown 2>/dev/null || true
