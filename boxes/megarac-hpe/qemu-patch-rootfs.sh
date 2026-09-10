#!/usr/bin/env bash
# qemu-patch-rootfs.sh <unpacked-rootfs-dir>
# Apply the emulation adaptations that let the Cray XD670 MegaRAC SP-X firmware run under qemu
# ast2600-evb. Called by extract.sh on the freshly-unsquashed rootfs before repacking.
#
# These rootfs adaptations align vendor configuration with the emulated machine. The final 2026-09-08
# GetDevID repair is owned by build-from-hpm.sh, which preserves the firmware-info FMH in NOR.
#
# FIX 1 — /conf seed + /conf/BMC symlink (etc/init.d/ipmistack).
#   IPMIMain opens the LITERAL path /conf/BMC/IPMI.conf to build its per-instance g_BMCInfo[] table.
#   Nothing creates the /conf/BMC -> BMC1/<platform> symlink under qemu (on HW the JFFS2 /conf seed +
#   platform detection do it), so seed the expected configuration before IPMIMain starts.
#   We seed /conf from /etc/defconfig and create the symlink before the first IPMIMain launch, gated
#   on a /conf/AMI sentinel (idempotent; /conf is persistent so it survives procmgr respawns).
#   (Also stages /tmp/devmap.xml for sdrgen/spx_restservice — orthogonal to the crash but harmless.)
#
# FIX 2 — make IPMI.conf consistent with qemu's modeled hardware.
#   qemu ast2600-evb provides: LAN (eth0), UDS (unix socket), KCS1-3 (ast-kcs-bmc). It has no ttyS2,
#   no usable host peer for ttyS3 SOL, and no i2c adapters (/sys/bus/i2c empty). A stock
#   IPMI.conf enables SERIAL/SOL (ttyS2/3), IPMB x5 + SMBUS (i2c), SMM (needs absent Smmchcfg.ini) and
#   BT (needs /dev/ipmi-bt-host). Ghidra RE of IPMIConf.c found a Node-Manager guard: it self-stops
#   unless NM_IPMB_BUS is 0/1/2 and that IPMB bus is enabled; the
#   disable value is NM_IPMB_BUS=0xFF (>=3 falls through the check). So: disable every absent-hardware
#   interface AND set NM_IPMB_BUS=0xFF. Keep KCS1-3 enabled: qemu supplies all three devices, and the
#   accepted rootfs does too. Kept ON: LAN, UDS, KCS1-3, DCMI and GROUP_EXTN.
#
# STATUS (2026-09-08): two clean attempt-1 boots with the deterministic image reached authenticated
#   Redfish Managers and LAN IPMI and held all required services continuously for at least 60 seconds.
#   Shell: dropbear SSH on port 22 (sysadmin/blank; musl soft-float ARMv5T static); mini_telnetd on
#   port 23 (no auth, direct /bin/sh). The old warm QMP snapshot is incompatible with current QEMU.
set -eu
R="${1:?usage: qemu-patch-rootfs.sh <rootfs-dir>}"

# --- FIX 1: seed /conf + /conf/BMC symlink, injected before each IPMIMain launch in ipmistack ------
IPMISTACK="$R/etc/init.d/ipmistack"
SEED='    mkdir -p /conf /var/tmp\n    if [ ! -f /conf/AMI ]; then\n        cp -a /etc/defconfig/* /conf/ 2>/dev/null\n        ln -sfn BMC1/ast2600evb_ami /conf/BMC\n        touch /conf/AMI\n    fi\n    { [ -f /tmp/devmap.xml ] || cp /etc/devmaps/MSB3/G593-SD0-AAQ1-HP0.xml /tmp/devmap.xml 2>/dev/null || cp /etc/devmaps/empty.xml /tmp/devmap.xml 2>/dev/null; }\n'
# insert the seed block immediately before every "/usr/local/bin/IPMIMain --daemonize" line
# Keep IPMIMain diagnostics on serial: the cold-start health gate uses its exact MsgHndlr SIGSEGV
# message to reject a bad attempt instead of waiting for an external timeout.
perl -0pi -e "s{([ \t]*)(/usr/local/bin/IPMIMain --daemonize --reg-with-procmgr)(\n)}{${SEED}\$1\$2\$3}g" "$IPMISTACK"

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

# --- FIX 4: dropbear SSH on :22 + telnetd on :23 -----------------------------------------------
#   Two static ARM binaries from prebuilt/:
#
#   prebuilt/dropbear — musl-linked soft-float static dropbear 2024.86. Built via Docker +
#     musl.cc arm-linux-musleabi cross-compiler (x86-32 Linux ELF, run inside debian:12-slim).
#     soft-float EABI, ARMv5T, no PT_INTERP — runs on any ARM without VFP. All *hard-float*
#     prebuilt dropbears SIGILL on ast2600-evb Cortex-A7 because qemu ast2600-evb doesn't
#     emulate VFP/NEON (despite the real Cortex-A7 supporting it in hardware).
#     Auth: blank password via -B. sysadmin shell + shadow fixed directly below (rootfs writable
#     at patch time — no bind-mount needed at runtime).
#   prebuilt/telnetd — mini_telnetd ARMv4T soft-float truly-static (@therealsaumil static-arm-
#     bins). No auth, direct /bin/sh. Port 23 (separate hostfwd in boot-megarac-hpe-svc.sh).
#
#   qemu hostfwd: :22 → SSH (dropbear); :23 → telnet (mini_telnetd).
#   Access: zbmc_ssh (sshpass sysadmin/blank); zbmc_telnet / nc 10.0.6.66 23.

# /etc/passwd + /etc/shadow are SYMLINKS -> /conf/passwd, /conf/shadow in the squashfs.
# /conf is the persistent flash partition seeded at boot by `cp -a /etc/defconfig/* /conf/`.
# Patch the SEED files in /etc/defconfig/ — they become /conf/passwd and /conf/shadow at runtime.
#   passwd: change sysadmin shell /usr/local/bin/defshell -> /bin/sh (dropbear whitelist).
#   shadow: blank sysadmin pw hash (field 2 empty = no pw; dropbear -B allows blank-pw login).
#   Original shadow hash: 3y0qpRW/8peJ6 (DES-crypt); cleared to avoid needing to crack it.
DC="$R/etc/defconfig"
sed -i.bak -E 's|^(sysadmin:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:)/usr/local/bin/defshell$|\1/bin/sh|' \
    "$DC/passwd"
rm -f "$DC/passwd.bak"
sed -i.bak -E 's|^(sysadmin:)[^:]*(:)|\1\2|' "$DC/shadow"
rm -f "$DC/shadow.bak"

# /etc/dropbear -> /var/dropbear/ symlink: dropbear -R auto-generates host keys in /etc/dropbear/
# (hardcoded default). /etc is squashfs RO at runtime so it can't create the dir there. Solution:
# bake the symlink into the squashfs at patch time; /var/ is tmpfs (writable) so dropbear can write.
# mkdir -p /var/dropbear in the init shim ensures the target exists before dropbear runs.
ln -sfn /var/dropbear "$R/etc/dropbear"

SHDIR="$R/usr/local/bin"
install -d -m 0755 "$SHDIR"
PROJ_PB="$(cd "$(dirname "$0")" && pwd)/prebuilt"
# Write launcher stanza to a temp file to avoid nested heredoc/escape hell, then perl-inject.
SHLAUNCH_TMP="$(mktemp)"
cat > "$SHLAUNCH_TMP" <<'SSHS'

    # qemu shim: dropbear SSH on port 22 (musl soft-float static; blank-password -B)
    # /etc/dropbear is a symlink -> /var/dropbear/ (writable tmpfs, created in squashfs at patch time).
    # dropbear -R auto-generates keys in /etc/dropbear/ = /var/dropbear/ which is writable.
    if [ -x /usr/local/bin/dropbear ]; then
        mkdir -p /var/log /var/run /var/dropbear
        /usr/local/bin/dropbear -R -p 22 -B -E >>/var/log/dropbear.log 2>&1 &
    fi
    # qemu shim: mini_telnetd on port 23 (ARMv4T static; no auth, direct /bin/sh root shell)
    if [ -x /usr/local/bin/telnetd ] && ! pidof telnetd >/dev/null 2>&1; then
        /usr/local/bin/telnetd -l /bin/sh -p 23 &
    fi
SSHS
SHLAUNCH_CONTENT="$(cat "$SHLAUNCH_TMP")"
rm -f "$SHLAUNCH_TMP"
if [ -f "$PROJ_PB/dropbear" ]; then
  install -m 0755 "$PROJ_PB/dropbear" "$SHDIR/dropbear"
  SHLAUNCH_ENV="$SHLAUNCH_CONTENT" perl -0777 -i -pe 's{(/usr/local/bin/IPMIMain --daemonize --reg-with-procmgr(?: >/dev/null 2>&1)?)}{$1 . $ENV{SHLAUNCH_ENV}}ge' "$IPMISTACK"
  echo "[qemu-patch] dropbear (musl soft-float ARMv5T) -> /usr/local/bin/dropbear; SSH on port 22 (sysadmin/blank)"
else
  echo "[qemu-patch] WARN: prebuilt/dropbear missing; SSH unavailable"
fi
if [ -f "$PROJ_PB/telnetd" ]; then
  install -m 0755 "$PROJ_PB/telnetd" "$SHDIR/telnetd"
  echo "[qemu-patch] telnetd (ARMv4T static) -> /usr/local/bin/telnetd; telnet on port 23 (no auth)"
else
  echo "[qemu-patch] WARN: prebuilt/telnetd missing; telnetd unavailable"
fi

# --- FIX 5: bypass getty on console — direct /bin/sh (no login, no PAM, no race) --------------------
#   Console login is racy: IPMIMain's crash-loop respawn floods ttyS4 stderr, drowning login's
#   password prompt so busybox `login` never sees the user's echoed cred. Rather than fight the
#   race, replace the `getty -L console 115200 vt100` line in /etc/inittab with a bare `/bin/sh`
#   respawn — no login required, root shell drops in immediately. Only reasonable because this is
#   a dev vBMC with no external LAN attackers; NEVER ship this to real hardware.
INIT="$R/etc/inittab"
if [ -f "$INIT" ]; then
    sed -i.bak -E 's|^(co:[0-9]+:respawn:).*|\1/bin/sh -i <>/dev/console >\&0 2>\&0|' "$INIT"
    rm -f "$INIT.bak"
fi

# Also silence processmanager (respawn spam of "Process(...) stopped, so respawning")
PROCMGR="$R/etc/init.d/procmanager"
if [ -f "$PROCMGR" ]; then
    sed -i.bak -E 's|(/usr/local/bin/processmanager) &|\1 >/dev/null 2>\&1 \&|' "$PROCMGR"
    rm -f "$PROCMGR.bak"
fi

# --- FIX 6: early /conf seed script at S07 — before S10gbt-init writes to /conf/BMC1/ ----------
#   FIX 1 seeds /conf inside ipmistack (S22). But S10gbt-init.sh and neighbouring scripts write
#   to /conf/BMC1/ast2600evb_ami/ BEFORE S22, producing:
#     cp: can't create '/conf/BMC1/ast2600evb_ami/pci_devices.json': No such file or directory
#     cp: can't create '/conf/BMC1/ast2600evb_ami/SDR.dat': No such file or directory
#   Also ipmistack reads /conf/pam_withunix + /conf/pam_wounix to configure PAM BEFORE launching
#   IPMIMain, so the FIX 1 injection (just before IPMIMain --daemonize) is too late for PAM too.
#   Both pam_withunix and pam_wounix live in /etc/defconfig/ alongside BMC1/ast2600evb_ami/,
#   so the existing `cp -a /etc/defconfig/* /conf/` covers everything — it just needs to run earlier.
#   S06mountall.sh mounts /conf from flash; S07 is the next free slot before S10.
#   The /conf/AMI sentinel makes FIX 1 (inside ipmistack) a no-op if S07 already ran — idempotent.
cat > "$R/etc/rcS.d/S07conf-seed.sh" <<'CONFSEED'
#!/bin/sh
# Early /conf seed — before S10gbt-init.sh and ipmistack need /conf/BMC1/ast2600evb_ami/ and PAM files.
# /conf is mounted by S06mountall.sh; /etc/defconfig has BMC1/ast2600evb_ami/, pam_withunix, pam_wounix.
if [ ! -f /conf/AMI ]; then
    cp -a /etc/defconfig/* /conf/ 2>/dev/null || true
    touch /conf/AMI
fi
# The flash template and warm snapshots may already contain /conf/AMI plus an older
# generated IPMI.conf.  In that case the bulk seed above correctly stays out of the
# way, but the emulation-safe interface mask must still win on every boot.
ln -sfn BMC1/ast2600evb_ami /conf/BMC
cp -f /etc/defconfig/BMC1/ast2600evb_ami/IPMI.conf \
      /conf/BMC1/ast2600evb_ami/IPMI.conf 2>/dev/null || true
# Unconditional: fix sysadmin shell + blank password regardless of whether the bulk seed ran.
# Required so warm snapshots from stale /conf don't block dropbear SSH (defshell is rejected;
# unknown pw hash prevents blank-password login even with dropbear -B).
# busybox sed: no -E; use BRE with simple literal patterns to avoid portability issues.
sed -i 's|/usr/local/bin/defshell|/bin/sh|' /conf/passwd 2>/dev/null || true
sed -i 's|^sysadmin:[^:]*:|sysadmin::|' /conf/shadow 2>/dev/null || true
{ [ -f /tmp/devmap.xml ] || \
  cp /etc/devmaps/MSB3/G593-SD0-AAQ1-HP0.xml /tmp/devmap.xml 2>/dev/null || \
  cp /etc/devmaps/empty.xml /tmp/devmap.xml 2>/dev/null; } || true
CONFSEED
chmod 0755 "$R/etc/rcS.d/S07conf-seed.sh"

cat > "$R/etc/rc3.d/S99zbmc-network" <<'NETWORK'
#!/bin/sh
killall udhcpc 2>/dev/null || true
ip link set eth0 up
ip addr flush dev eth0 scope global
ip addr add 10.250.0.40/8 dev eth0
ip route replace default via 10.0.0.1 dev eth0
NETWORK
chmod 0755 "$R/etc/rc3.d/S99zbmc-network"

echo "[qemu-patch] ipmistack conf-seed+symlink injected; IPMI.conf keeps qemu-backed LAN/UDS/KCS1-3/DCMI"
echo "[qemu-patch] serial/sol/bt/smm/smbus/ipmb, NM_IPMB_BUS=0xFF -> IPMIMain stable, UDS listens, authed Redfish works"
echo "[qemu-patch] smash shim -> /bin/sh (console login as admin/superuser works)"
echo "[qemu-patch] inittab console: getty -> /bin/sh -i (no login prompt, direct root shell)"
echo "[qemu-patch] S07conf-seed.sh -> seeds /conf before early consumers"
echo "[qemu-patch] sysadmin /etc/passwd shell: /usr/local/bin/defshell -> /bin/sh; shadow pw hash cleared"
echo "[qemu-patch] dropbear SSH on port 22 (sysadmin/blank via -B); telnetd on port 23 (no auth)"
