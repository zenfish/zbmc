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
#   qemu ast2600-evb provides: LAN (eth0), UDS (unix socket), KCS1-3 (ast-kcs-bmc). It has NO
#   /dev/ttyS2/ttyS3 (kernel wires only ttyS0/ttyS4) and NO i2c adapters (/sys/bus/i2c empty). A stock
#   IPMI.conf enables SERIAL/SOL (ttyS2/3), IPMB x5 + SMBUS (i2c), SMM (needs absent Smmchcfg.ini) and
#   BT (needs /dev/ipmi-bt-host); each leaves a half-initialised table entry the central MsgHndlr
#   thread later derefs -> SIGSEGV -> procmgr 15x -> BMC reboot. Ghidra RE of IPMIConf.c also found a
#   Node-Manager guard: it self-stops unless NM_IPMB_BUS is 0/1/2 AND that IPMB bus is enabled; the
#   disable value is NM_IPMB_BUS=0xFF (>=3 falls through the check). So: disable every absent-hardware
#   interface AND set NM_IPMB_BUS=0xFF. KCS1-3 also disabled: even though ast-kcs-bmc hw exists,
#   keeping KCS enabled caused early crashes (interface init failures → table corruption).
#   Kept ON: LAN, UDS, DCMI (needs GROUP_EXTN, which stays 1).
#   Result: IPMIMain runs stable and UDS server /var/UDSocket1 listens from boot.
#
# STATUS (2026-08-20): all fixes applied → cold boot stable (0 IPMIMain SIGSEGVs on 3rd try),
#   UDS listens (/var/UDSocket1), MsgHndlr health counter updates via UDS clients → thread monitor
#   never fires, admin/superuser provisioned at boot, authenticated Redfish works. LAN IPMI (UDP/623)
#   still doesn't bind (libipmilan init race TBD). Warm QMP snapshot at work/cray-snap.gz restores
#   in ~10s skipping the 5-min cold boot entirely.
set -eu
R="${1:?usage: qemu-patch-rootfs.sh <rootfs-dir>}"

# --- FIX 1: seed /conf + /conf/BMC symlink, injected before each IPMIMain launch in ipmistack ------
IPMISTACK="$R/etc/init.d/ipmistack"
SEED='    mkdir -p /conf /var/tmp\n    if [ ! -f /conf/AMI ]; then\n        cp -a /etc/defconfig/* /conf/ 2>/dev/null\n        ln -sfn BMC1/ast2600evb_ami /conf/BMC\n        touch /conf/AMI\n    fi\n    { [ -f /tmp/devmap.xml ] || cp /etc/devmaps/MSB3/G593-SD0-AAQ1-HP0.xml /tmp/devmap.xml 2>/dev/null || cp /etc/devmaps/empty.xml /tmp/devmap.xml 2>/dev/null; }\n'
# insert the seed block immediately before every "/usr/local/bin/IPMIMain --daemonize" line
# ALSO: append `>/dev/null 2>&1` INLINE (same line as IPMIMain) so its crash-loop spam doesn't
# drown the console tty. Console readability is critical when FIX 5 replaces getty with /bin/sh -i.
# Anchor perl regex on the FULL line including trailing whitespace/newline to keep redirect on same line.
perl -0pi -e "s{([ \t]*)(/usr/local/bin/IPMIMain --daemonize --reg-with-procmgr)(\n)}{${SEED}\$1\$2 >/dev/null 2>&1\$3}g" "$IPMISTACK"

# --- FIX 2: disable the hardware-less IPMI interfaces in the seed IPMI.conf ------------------------
IC="$R/etc/defconfig/BMC1/ast2600evb_ami/IPMI.conf"
sed -i.bak -E \
 -e 's/^([[:space:]]*SUPPORT_SERIAL_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_SOL_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_SMM_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_SMBUS_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_BT_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_KCS1_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_KCS2_IFC=)1/\10/' \
 -e 's/^([[:space:]]*SUPPORT_KCS3_IFC=)1/\10/' \
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
  # /etc is squashfs (RO). dropbear -R writes host keys to /etc/dropbear/, so redirect that path
  # to /var/dropbear (tmpfs, writable) via a build-time symlink. Confirmed via early boot log line
  # "mkdir: can't create directory '/etc/dropbear': Read-only file system" — dropbear died at key
  # gen without this. /var is a tmpfs mounted by AMI init before rc3, so the symlink resolves.
  rm -f "$R/etc/dropbear" 2>/dev/null
  ln -sfn /var/dropbear "$R/etc/dropbear"
  # Write launcher stanza to a temp file to avoid nested escape hell, then perl-inject.
  DBLAUNCH_TMP="$(mktemp)"
  cat > "$DBLAUNCH_TMP" <<'DBS'

    # qemu shim: dropbear sshd (host-key auto-gen via -R -> /var/dropbear via symlink)
    if [ -x /usr/local/bin/dropbear ] && ! pidof dropbear >/dev/null 2>&1; then
        mkdir -p /var/dropbear /var/log /var/run
        [ -c /dev/pts/0 ] || mount -t devpts devpts /dev/pts 2>/dev/null || true
        /usr/local/bin/dropbear -R -p 22 -B -E >>/var/log/dropbear.log 2>&1 &
    fi
DBS
  DBLAUNCH_CONTENT="$(cat "$DBLAUNCH_TMP")"
  rm -f "$DBLAUNCH_TMP"
  # perl -0777 slurps the whole file; use a Perl variable to hold the injection text safely.
  # Anchor on the FIX 1-modified line (already has `>/dev/null 2>&1` from perl above); inject stanza AFTER that suffix.
  DBLAUNCH_ENV="$DBLAUNCH_CONTENT" perl -0777 -i -pe 's{(/usr/local/bin/IPMIMain --daemonize --reg-with-procmgr(?: >/dev/null 2>&1)?)}{$1 . $ENV{DBLAUNCH_ENV}}ge' "$IPMISTACK"
  echo "[qemu-patch] dropbear staged -> /usr/local/bin/dropbear; /etc/dropbear -> /var/dropbear symlink; launcher injected in ipmistack"
else
  echo "[qemu-patch] WARN: prebuilt/dropbear missing; SSH will remain unavailable"
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
    ln -sfn BMC1/ast2600evb_ami /conf/BMC
    touch /conf/AMI
fi
{ [ -f /tmp/devmap.xml ] || \
  cp /etc/devmaps/MSB3/G593-SD0-AAQ1-HP0.xml /tmp/devmap.xml 2>/dev/null || \
  cp /etc/devmaps/empty.xml /tmp/devmap.xml 2>/dev/null; } || true
# libunix.so.13 waits for /var/tmp/rc-init-complete before calling listen() on /var/UDSocket1.
# Without this file, UDS refuses connections for ~6 min (until S99zz-rc-init-complete creates it),
# which matches the thread monitor's 36x10s=360s window exactly -> restart -> double-reg SIGSEGV.
# Creating it here (S07, before IPMIMain starts at S22) makes UDS accept immediately at startup.
mkdir -p /var/tmp
touch /var/tmp/rc-init-complete
CONFSEED
chmod 0755 "$R/etc/rcS.d/S07conf-seed.sh"

echo "[qemu-patch] ipmistack conf-seed+symlink injected; IPMI.conf: kept LAN/UDS/DCMI, disabled KCS1/2/3"
echo "[qemu-patch] serial/sol/bt/smm/smbus/ipmb, NM_IPMB_BUS=0xFF -> IPMIMain stable, UDS listens, authed Redfish works"
echo "[qemu-patch] smash shim -> /bin/sh (console login as admin/superuser works)"
echo "[qemu-patch] inittab console: getty -> /bin/sh -i (no login prompt, direct root shell)"
echo "[qemu-patch] S07conf-seed.sh -> seeds /conf + rc-init-complete early; UDS listens from boot"
