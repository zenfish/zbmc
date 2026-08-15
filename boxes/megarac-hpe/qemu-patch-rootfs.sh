#!/usr/bin/env bash
# qemu-patch-rootfs.sh <unpacked-rootfs-dir>
# Apply the emulation adaptations that let the Cray XD670 MegaRAC SP-X firmware run under qemu
# ast2600-evb. Called by extract.sh on the freshly-unsquashed rootfs before repacking.
#
# Two fixes, both traced by Ghidra RE of IPMIMain / libipmimsghndlr.so / libipmistack.so (2026-07-28):
#
# FIX 1 — /conf seed + /conf/BMC symlink (etc/init.d/ipmistack).
#   IPMIMain opens the LITERAL path /conf/BMC/IPMI.conf to build its per-instance g_BMCInfo[] table.
#   Nothing creates the /conf/BMC -> BMC1/<platform> symlink under qemu (on HW the JFFS2 /conf seed +
#   platform detection do it). Missing it -> interface table never built -> MsgHndlr @0x14864 derefs
#   an uninitialised g_BMCInfo field -> SIGSEGV -> procmgr respawns -> 15 crashes -> BMC reboot loop.
#   We seed /conf from /etc/defconfig and create the symlink before the first IPMIMain launch, gated
#   on a /conf/AMI sentinel (idempotent; /conf is persistent so it survives procmgr respawns).
#   (Also stages /tmp/devmap.xml for sdrgen/spx_restservice — orthogonal to the crash but harmless.)
#
# FIX 2 — make the IPMI.conf consistent with qemu's hardware so IPMIMain doesn't crash or self-stop.
#   qemu ast2600-evb provides ONLY: LAN (eth0), UDS (unix socket), KCS1-3 (ast-kcs-bmc). It has NO
#   /dev/ttyS2/ttyS3 (kernel wires only ttyS0/ttyS4) and NO i2c adapters (/sys/bus/i2c empty). A stock
#   IPMI.conf enables SERIAL/SOL (ttyS2/3), IPMB x5 + SMBUS (i2c), SMM (needs absent Smmchcfg.ini) and
#   BT (needs /dev/ipmi-bt-host); each leaves a half-initialised table entry the central MsgHndlr
#   thread later derefs -> SIGSEGV -> procmgr 15x -> BMC reboot. Ghidra RE of IPMIConf.c also found a
#   Node-Manager guard: it self-stops unless NM_IPMB_BUS is 0/1/2 AND that IPMB bus is enabled; the
#   disable value is NM_IPMB_BUS=0xFF (>=3 falls through the check). So: disable every absent-hardware
#   interface AND set NM_IPMB_BUS=0xFF. Kept ON: LAN, UDS, KCS1-3 (present hw), DCMI (needs GROUP_EXTN,
#   which stays 1). Result: IPMIMain runs stable and binds its UDS server /var/UDSocket1.
#
# STATUS: with both fixes the box boots stable (no SIGSEGV/reboot loop), IPMIMain serves UDS, and
#   external Redfish ServiceRoot is reachable. Remaining: no IPMI user is provisioned in the empty
#   UserConfig.ini, so RMCP+ (623) + authed Redfish need a user seeded (WIP; see README.html).
set -eu
R="${1:?usage: qemu-patch-rootfs.sh <rootfs-dir>}"

# --- FIX 1: seed /conf + /conf/BMC symlink, injected before each IPMIMain launch in ipmistack ------
IPMISTACK="$R/etc/init.d/ipmistack"
# ALWAYS ensure the /conf/BMC symlink (NOT gated on /conf/AMI): the HPM's carved /conf already ships the
# AMI sentinel, so a gated create is skipped -> IPMIMain SIGSEGVs. Seed defconfig once; ensure symlink always.
SEED='    mkdir -p /conf /var/tmp\n    [ -f /conf/AMI ] || { cp -a /etc/defconfig/* /conf/ 2>/dev/null; touch /conf/AMI; }\n    [ -L /conf/BMC ] || ln -sfn BMC1/ast2600evb_ami /conf/BMC\n'
# insert the seed block immediately before every "/usr/local/bin/IPMIMain --daemonize" line
perl -0pi -e "s{([ \t]*)(/usr/local/bin/IPMIMain --daemonize --reg-with-procmgr)}{${SEED}\$1\$2}g" "$IPMISTACK"

# --- FIX 2: disable the hardware-less IPMI interfaces in the seed IPMI.conf ------------------------
IC="$R/etc/defconfig/BMC1/ast2600evb_ami/IPMI.conf"
sed -i.bak -E \
 -e 's/^([[:space:]]*SUPPORT_SERIAL_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_SOL_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_SMM_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_SMBUS_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_BT_IFC=)1/\10/' \
 -e 's/^([[:space:]]*PRIMARY_IPMB_SUPPORT=)1/\10/' \
 -e 's/^([[:space:]]*SECONDARY_IPMB_SUPPORT=)1/\10/' \
 -e 's/^([[:space:]]*THIRD_IPMB_SUPPORT=)1/\10/' \
 -e 's/^([[:space:]]*FOURTH_IPMB_SUPPORT=)1/\10/' \
 -e 's/^([[:space:]]*FIFTH_IPMB_SUPPORT=)1/\10/' \
 -e 's/^([[:space:]]*NM_IPMB_BUS=)0x1/\10xFF/' \
 "$IC"
rm -f "$IC.bak"

echo "[qemu-patch] ipmistack conf-seed+symlink injected; IPMI.conf: kept LAN/UDS/KCS, disabled"
echo "[qemu-patch] serial/sol/bt/smm/smbus/ipmb, NM_IPMB_BUS=0xFF -> IPMIMain stable + UDS serving"
