#!/usr/bin/env bash
# boot-megarac-hpe-svc.sh — boot the HPE Cray XD670 MegaRAC SP-X BMC with REAL init (/sbin/init) + networking.
#
# WHAT : full MegaRAC userland — mounts /conf & /bkupconf from the NAMED mtd partitions in mtdflash.bin,
#        runs sysvinit rc3 (redis, event-service, sync-agent, lighttpd/Redfish, IPMIMain, ...).
#        Serial console on ttyS4; getty login is sysadmin / superuser (MegaRAC factory default, uid 0,
#        restricted 'defshell').  qemu user-net maps 443/22/623 to the host on 127.0.0.1.
# WHY  : this is the tier that exercises the real attack surface (Redfish = Eclypsium CVE-2024-54085
#        lua at /usr/local/redfish/extensions/host-interface/host-interface-support-module.lua).
#
# STATUS (2026-07-28): extract.sh injects the devmap shim that fixes the IPMIMain MsgHndlr SIGSEGV, so
#   the IPMI stack stays up, eth0 gets a DHCP lease, and the Redfish server is externally reachable:
#     curl -sk https://<IP>/redfish/v1/  ->  AMI Redfish Server, Redfish 1.11.0 (ServiceRoot, public).
#   REMAINING: protected Redfish (auth backend: PAM->IPMI user table) + IPMI-623 RMCP+ not serving yet.
#
# KEY: mtdparts names MUST match extract.sh's layout — mountall.sh greps /proc/mtd for 'conf'/'bkupconf'.
# RUN  : ./boot-megarac-hpe-svc.sh              (foreground, console = your terminal)
#        BG=1 ./boot-megarac-hpe-svc.sh         (background via a fifo; console -> $WD/svc.log, drive via $WD/cin)
# RELATED: extract.sh, boot-megarac-hpe.sh, zbmc.box.
set -u
WD="${WD:-/Users/zen/phd/tmp/cray-xd670}"
IP="${IP:-127.0.0.1}"
# Standard ports 443/623 are privileged -> qemu must run as root to bind them on the real IP (matches
# restore-megarac-hpe.sh's root-direct model). Loopback dev with high ports (8443/8623) needs no root.
SUDO=; [ "$(id -u)" = 0 ] || SUDO=sudo
# host-side forward ports. Zoo/real-IP use = standard ports (needs root to bind 443/623); loopback dev
# use = pass HTTPS_PORT=8443 SSH_PORT=8022 IPMI_PORT=8623 to avoid root. Guest side is always 443/22/623.
HTTPS_PORT="${HTTPS_PORT:-443}"; SSH_PORT="${SSH_PORT:-22}"; IPMI_PORT="${IPMI_PORT:-623}"
MTDPARTS='mtdparts=1e620000.spi:1M(uboot),2M(conf),2M(bkupconf),1M(extlog),4M(www),-(root)'
APPEND="console=ttyS4,115200n8 root=/dev/ram0 ro rootfstype=squashfs ramdisk_size=131072 ramdisk_blocksize=4096 $MTDPARTS rootwait"
# Boot from a FRESH copy of the pristine flash each start: IPMIMain only auto-provisions the default
# admin/superuser user when /conf is clean (a stale UserConfig.ini is kept as-is). Master stays pristine.
cp -f "$WD/mtdflash.bin" "$WD/mtdflash-run.bin"
# -qmp socket: lets snapshot-megarac-hpe.sh checkpoint a green instance (QMP migrate->gz). Removed+recreated.
rm -f "$WD/cray-qmp.sock"
QEMU=(qemu-system-arm -M ast2600-evb -m 1024 -nographic
  -qmp "unix:$WD/cray-qmp.sock,server,nowait"
  -kernel "$WD/kernel.Image" -dtb "$WD/dtb-a1.dtb" -initrd "$WD/rootfs.sqfs"
  -drive "file=$WD/mtdflash-run.bin,format=raw,if=mtd"
  -net nic -net "user,hostfwd=tcp:$IP:$HTTPS_PORT-:443,hostfwd=tcp:$IP:$SSH_PORT-:22,hostfwd=udp:$IP:$IPMI_PORT-:623,hostname=megarac-hpe"
  -append "$APPEND")

if [ "${BG:-}" = 1 ]; then
  cd "$WD"; rm -f cin; mkfifo cin; : > svc.log
  ( tail -f cin ) | $SUDO "${QEMU[@]}" > svc.log 2>&1 &
  echo "backgrounded. console -> $WD/svc.log ; send input: echo 'cmd' > $WD/cin ; login admin/superuser"
else
  exec $SUDO "${QEMU[@]}"
fi
