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
SEED='    mkdir -p /conf /var/tmp\n    if [ ! -f /conf/AMI ]; then\n        cp -a /etc/defconfig/* /conf/ 2>/dev/null\n        ln -sfn BMC1/ast2600evb_ami /conf/BMC\n        touch /conf/AMI\n    fi\n    { [ -f /tmp/devmap.xml ] || cp /etc/devmaps/MSB3/G593-SD0-AAQ1-HP0.xml /tmp/devmap.xml 2>/dev/null || cp /etc/devmaps/empty.xml /tmp/devmap.xml 2>/dev/null; }\n'
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

# --- FIX 3: smash shim so the console login shell exists ------------------------------------------
#   IPMIMain provisions the 'admin' Linux account with login shell /usr/local/bin/smash (SMASH-CLP),
#   but this build ships NO smash binary (only defshell) -> `console` login as admin bounces with
#   "login: can't execute '/usr/local/bin/smash'" and logs straight back out. admin/superuser already
#   AUTHENTICATES (same cred as the IPMI user), so a shim that execs an interactive shell turns the
#   console into a working root login on the live service box (admin is uid 0 here). ssh stays broken
#   for a different reason — this rootfs has no sshd binary or ssh-main startup script at all.
install -d -m 0755 "$R/usr/local/bin"
cat > "$R/usr/local/bin/smash" <<'SMASH'
#!/bin/sh
# qemu shim: this MegaRAC build has no SMASH-CLP binary; give the console account a real shell.
exec /bin/sh "$@"
SMASH
chmod 0755 "$R/usr/local/bin/smash"

# --- FIX 4: dropbear sshd — give host-side SSH access on :22 ---------------------------------------
#   This rootfs has neither an sshd binary nor an ssh-main startup script, so guest port 22 sits
#   forwarded (see boot-megarac-hpe-svc.sh hostfwd) but nothing binds to answer. We inject a static
#   ARMv7 dropbear from prebuilt/ (source: https://kuba.szczodrzynski.pl/tools/linux-static-binaries/,
#   static-pie, ~300 KB, no libc deps) and hook the launch onto `ipmistack` — the same init script
#   FIX 1 already patches, so we know it runs. rc3.d/S99 was tried first but AMI's init dispatcher
#   didn't invoke it; ipmistack is proven-live. Host keys auto-generate on first connect via `-R`
#   (no dropbearkey needed). Auth path: dropbear → PAM → /etc/shadow (same as console getty).
#   FIX 3's smash shim ensures admin's login shell exists.
DBDIR="$R/usr/local/bin"
install -d -m 0755 "$DBDIR"
PROJ_PB="$(cd "$(dirname "$0")" && pwd)/prebuilt"
if [ -f "$PROJ_PB/dropbear" ]; then
  install -m 0755 "$PROJ_PB/dropbear" "$DBDIR/dropbear"
  # Inject dropbear launcher INSIDE the start) branch of ipmistack, immediately after IPMIMain
  # exec's — must land inside the case-statement, not after `esac; exit 0`. Anchor on the same
  # IPMIMain launch line FIX 1 already targets.
  DBLAUNCH='\n    # qemu shim: dropbear sshd (host-key auto-gen via -R; auth = PAM \/ \/etc\/shadow)\n    if [ -x \/usr\/local\/bin\/dropbear ] \&\& ! pidof dropbear >\/dev\/null 2>\&1; then\n        mkdir -p \/etc\/dropbear \/var\/log \/var\/run\n        [ -c \/dev\/pts\/0 ] || mount -t devpts devpts \/dev\/pts 2>\/dev\/null || true\n        \/usr\/local\/bin\/dropbear -R -p 22 -B >>\/var\/log\/dropbear.log 2>\&1 \&\n    fi'
  perl -0pi -e "s{(/usr/local/bin/IPMIMain --daemonize --reg-with-procmgr)}{\$1${DBLAUNCH}}g" "$IPMISTACK"
  echo "[qemu-patch] dropbear (static-pie ARMv7 from prebuilt/) staged -> /usr/local/bin/dropbear; launcher injected after IPMIMain in ipmistack"
else
  echo "[qemu-patch] WARN: prebuilt/dropbear missing; SSH will remain unavailable"
fi

echo "[qemu-patch] ipmistack conf-seed+symlink injected; IPMI.conf: kept LAN/UDS/KCS, disabled"
echo "[qemu-patch] serial/sol/bt/smm/smbus/ipmb, NM_IPMB_BUS=0xFF -> IPMIMain stable + UDS serving"
echo "[qemu-patch] smash shim -> /bin/sh (console login as admin/superuser works)"
