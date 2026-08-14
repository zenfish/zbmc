#!/usr/bin/env bash
# qemu-patch-rootfs.sh <unpacked-rootfs-dir>
# Emulation adaptations letting the Advantech ASMB-787 MegaRAC SP-X 4.0 firmware run under
# qemu ast2600-evb. Ported from the HPE Cray XD670 box (same AMI SP-X / ast2600evb_ami platform).
#
# FIX 1 — /conf seed + /conf/BMC symlink (etc/init.d/ipmistack).
#   IPMIMain opens the LITERAL /conf/BMC/IPMI.conf to build g_BMCInfo[]. Under qemu nothing creates
#   the /conf/BMC -> BMC1/ast2600evb_ami symlink, so the interface table is never built and the central
#   MsgHndlr derefs an uninit g_BMCInfo field -> SIGSEGV -> procmgr respawn loop -> reboot. We seed
#   /conf from /etc/defconfig once (gated on /conf/AMI) and ALWAYS ensure the symlink, before each
#   IPMIMain launch (idempotent; /conf is a persistent mount so it survives respawns).
#   (No devmap shim: ASMB /etc/devmaps is empty and the devmap is orthogonal to the crash.)
#
# FIX 2 — make IPMI.conf consistent with qemu hardware. ast2600-evb has LAN(eth0)+UDS+KCS1-3 only;
#   no ttyS2/3 (SOL), no i2c (SMBUS/IPMB), no Smmchcfg.ini (SMM). Each absent-hw interface leaves a
#   half-init table entry the MsgHndlr later derefs -> SIGSEGV. Also the Node-Manager guard self-stops
#   unless NM_IPMB_BUS is 0/1/2 AND that bus is enabled -> set 0xFF to fall through. ASMB defconfig
#   already has SERIAL/SMBUS/BT/IPMB=0, so only SMM, SOL, NM_IPMB_BUS need flipping. Keep LAN/UDS/KCS.
set -eu
R="${1:?usage: qemu-patch-rootfs.sh <rootfs-dir>}"

# --- FIX 1: inject conf-seed + symlink before every IPMIMain launch in ipmistack -------------------
IPMISTACK="$R/etc/init.d/ipmistack"
SEED='    mkdir -p /conf /var/tmp\n    [ -f /conf/AMI ] || { cp -a /etc/defconfig/* /conf/ 2>/dev/null; touch /conf/AMI; }\n    [ -L /conf/BMC ] || ln -sfn BMC1/ast2600evb_ami /conf/BMC\n'
perl -0pi -e "s{([ \t]*)(/usr/local/bin/IPMIMain --daemonize --reg-with-procmgr)}{${SEED}\$1\$2}g" "$IPMISTACK"

# --- FIX 2: disable hardware-less IPMI interfaces in the seed IPMI.conf ----------------------------
IC="$R/etc/defconfig/BMC1/ast2600evb_ami/IPMI.conf"
sed -i.bak -E \
 -e 's/^([[:space:]]*SUPPORT_SMM_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_SOL_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_SERIAL_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_SMBUS_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_BT_IFC=)1/\10/' \
 -e 's/^([[:space:]]*(PRIMARY|SECONDARY|THIRD|FOURTH|FIFTH)_IPMB_SUPPORT=)1/\10/' \
 -e 's/^([[:space:]]*NM_IPMB_BUS=)0x1/\10xFF/' \
 "$IC"
rm -f "$IC.bak"

echo "[qemu-patch] ipmistack conf-seed+/conf/BMC symlink injected; IPMI.conf: kept LAN/UDS/KCS,"
echo "[qemu-patch] disabled smm/sol/serial/smbus/bt/ipmb, NM_IPMB_BUS=0xFF -> IPMIMain stable"
