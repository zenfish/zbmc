#!/usr/bin/env bash
#
# shell-x14.sh — COLD-boot the virtual X14 BMC into interactive-shell mode (PID1 = /bin/sh).
#
# WHAT:   Boots the vendor kernel+initramfs under qemu ast2600-evb, but the patched init
#         (qemu-x14-shell token) execs /bin/sh as PID1 instead of systemd. Serial is a
#         unix socket (serial.sock) so we drive the shell over socat. QMP on
#         qmp.sock for checkpointing.
# WHY:    A COLD boot's guest network is ALIVE (eth0 packets round-trip host<->guest over
#         qemu user-net/hostfwd). The warm -incoming restore comes up network-DEAD (the
#         ast2600 ftgmac100 NIC doesn't re-deliver to the guest post-migration, same class
#         as the idrac9 usb-net issue). So for LIVE external IPMI/Redfish we cold-boot and
#         bring the daemons up by hand (bringup-ipmi.sh) in the correct order.
# NET:    10.0.8.14 (Linux loopback alias). hostfwd 22/443->tcp, 623->udp to guest 10.0.2.15.
# RUN:    WD=/path/to/work/supermicro-x14 ./shell-x14.sh &   then drive via socat serial.sock
# AFTER:  once at the sh-5.1# prompt, run bringup-ipmi.sh in the guest, then from the host:
#         ipmitool -I lanplus -H 10.0.8.14 -U ADMIN -P ADMIN mc info
#
set -euo pipefail
cd "${WD:-$(dirname "$0")}"
IP="${ZBMC_IP:-10.0.8.14}"
CONSOLE_LOG="${ZBMC_CONSOLE_LOG:-console-uart.log}"
BOOT_TOKEN="${X14_BOOT_TOKEN:-qemu-x14-shell}"
ip addr show dev lo | grep -qw "$IP" || sudo ip addr add "$IP/32" dev lo
sudo -n pkill -9 -f "hostname=x14bmc" 2>/dev/null || true; sleep 2
sudo -n rm -f serial.sock qmp.sock
QEMU="${QEMU:-$(command -v qemu-system-arm)}"
exec sudo "$QEMU" \
  -m 1024 -M ast2600-evb -display none -no-reboot \
  -chardev "socket,id=serial0,path=serial.sock,server=on,wait=off,logfile=$CONSOLE_LOG,logappend=off" \
  -serial chardev:serial0 \
  -qmp unix:qmp.sock,server,nowait \
  -kernel kernel.bin -dtb x14-noncsi.dtb -initrd initramfs-patched.bin \
  -drive file=x14-ce0-64m.img,format=raw,if=mtd,snapshot=on \
  -drive file=emmc.img,format=raw,if=sd,index=2,snapshot=on \
  -net nic -net user,hostfwd=tcp:$IP:${SSH_PORT:-22}-:22,hostfwd=tcp:$IP:${WEB_PORT:-443}-:443,hostfwd=udp:$IP:623-:623,hostname=x14bmc \
  -append "console=ttyS4,115200n8 root=/dev/ram rw maxcpus=1 initcall_blacklist=ast2600_spitee_init,optee_driver_init qemu-x14-ramroot $BOOT_TOKEN loglevel=4"
