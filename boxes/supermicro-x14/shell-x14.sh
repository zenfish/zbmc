#!/usr/bin/env bash
#
# shell-x14.sh — COLD-boot the virtual X14 BMC into interactive-shell mode (PID1 = /bin/sh).
#
# WHAT:   Boots the vendor kernel+initramfs under qemu ast2600-evb, but the patched init
#         (qemu-x14-shell token) execs /bin/sh as PID1 instead of systemd. Serial is a
#         unix socket (/tmp/x14.sock) so we drive the shell over socat. QMP on
#         /tmp/x14-qmp.sock for checkpointing.
# WHY:    A COLD boot's guest network is ALIVE (eth0 packets round-trip host<->guest over
#         qemu user-net/hostfwd). The warm -incoming restore comes up network-DEAD (the
#         ast2600 ftgmac100 NIC doesn't re-deliver to the guest post-migration, same class
#         as the idrac9 usb-net issue). So for LIVE external IPMI/Redfish we cold-boot and
#         bring the daemons up by hand (bringup-ipmi.sh) in the correct order.
# NET:    10.0.8.14 (lo0 alias). hostfwd 22/443->tcp, 623->udp to guest 10.0.2.15.
# RUN:    ~/phd/tmp/x14-virtual/shell-x14.sh &     then drive via socat /tmp/x14.sock
# AFTER:  once at the sh-5.1# prompt, run bringup-ipmi.sh in the guest, then from the Mac:
#         ipmitool -I lanplus -H 10.0.8.14 -U ADMIN -P ADMIN mc info
#
set -euo pipefail
cd "${WD:-$(dirname "$0")}"
IP=10.0.8.14
ifconfig lo0 | grep -q "$IP" || sudo ifconfig lo0 alias "$IP"
sudo -n pkill -9 -f "hostname=x14bmc" 2>/dev/null || true; sleep 2
sudo -n rm -f /tmp/x14.sock /tmp/x14-qmp.sock
exec sudo /opt/homebrew/bin/qemu-system-arm \
  -m 1024 -M ast2600-evb -display none -no-reboot \
  -serial unix:/tmp/x14.sock,server,nowait \
  -qmp unix:/tmp/x14-qmp.sock,server,nowait \
  -kernel kernel.bin -dtb x14-noncsi.dtb -initrd initramfs-patched.bin \
  -drive file=x14-ce0-64m.img,format=raw,if=mtd \
  -drive file=emmc.img,format=raw,if=sd,index=2 \
  -net nic -net user,hostfwd=tcp:$IP:22-:22,hostfwd=tcp:$IP:443-:443,hostfwd=udp:$IP:623-:623,hostname=x14bmc \
  -append "console=ttyS4,115200n8 root=/dev/ram rw maxcpus=1 initcall_blacklist=ast2600_spitee_init,optee_driver_init qemu-x14-ramroot qemu-x14-shell loglevel=4"
