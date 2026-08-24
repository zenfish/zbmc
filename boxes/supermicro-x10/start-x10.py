#!/usr/bin/env python3
"""Durable X10 BMC boot driver (Supermicro X10 / ASPEED AST2400, FW 3.93).

Boots the 32MB flash under qemu -M supermicrox11-bmc, then drives the serial
console to fix networking, patch SSH, and bypass the OEM license gate:

  1. NETWORKING — firmware zeroes its MAC (no FRU/EEPROM in a flat image) and
     fails to bond eth0→bond0, so DHCP never leases. Sets a valid MAC, assigns
     the qemu user-net static IP, adds the default route. Re-applies after
     udhcpc gives up (race fix).

  2. SSH — bind-mounts a wrapper over /SMASH/msh (dropbear's hardcoded login
     shell) and restarts dropbear with explicit host key paths, so SSH sessions
     get /bin/ash instead of SMASH-CLP.

  3. REDFISH LICENSE BYPASS — LD_PRELOAD's a tiny ARM .so that overrides
     license_check() → return 1, then restarts lighttpd. Without this, all
     Redfish endpoints past /redfish/v1/ return 403 (OOB license required).

Serial is exposed as a UNIX socket ($SOCK) so `zbmc shell` / `zbmc console` can
connect interactively via socat after bootstrap completes. Pexpect disconnects
once all patches are applied, freeing the socket for interactive use.

Prints NET_CONFIGURED when done, then waits for qemu to exit.

Why this box exists: it offers IPMI 2.0 cipher suites 0-14 (incl. the RC4/MD5
suites 4,5,9-14 that modern firmware dropped) — the authorized local oracle for
verifying zipmi's MD5-128 + xRC4 implementations.
"""
import sys, os, time, subprocess, signal, pexpect

SELF = os.path.dirname(os.path.abspath(__file__))                                # box scripts dir
WD = os.environ.get("WD", SELF)                                                 # artifacts/logs
MASTER = os.environ.get("X10_MASTER", os.path.join(WD, "x10-master.flash"))     # firmware seed
BYPASS_SO = os.path.join(SELF, "license_bypass.so")                              # LD_PRELOAD shim
RUN = os.path.join(WD, "x10-run.flash")
SOCK = os.path.join(WD, "x10-serial.sock")
HOSTIP   = os.environ.get("X10_HOSTIP", os.environ.get("ZBMC_IP", "10.0.8.10"))
HOSTPORT = os.environ.get("X10_HOSTPORT", "623")
SSH_HPORT = os.environ.get("X10_SSH_PORT", "22")
WEB_HPORT = os.environ.get("X10_WEB_PORT", "443")
import shutil as _sh
QEMU     = os.environ.get("X10_QEMU",
           _sh.which("qemu-system-arm") or "/opt/homebrew/bin/qemu-system-arm")

_sh.copyfile(MASTER, RUN)

# Clean stale socket
if os.path.exists(SOCK):
    os.unlink(SOCK)

# Launch QEMU with serial on a UNIX socket (not -nographic, which ties serial
# to stdio). -display none suppresses the GUI; -monitor none avoids the monitor
# prompt on stdio.
qemu_cmd = [
    "sudo", "-n", QEMU,
    "-m", "128", "-M", "supermicrox11-bmc",
    "-display", "none", "-monitor", "none",
    "-chardev", f"socket,id=ser0,path={SOCK},server=on,wait=off",
    "-serial", "chardev:ser0",
    "-drive", f"file={RUN},format=raw,if=mtd",
    "-net", "nic",
    "-net", f"user,hostfwd=udp:{HOSTIP}:{HOSTPORT}-:623,hostfwd=tcp:{HOSTIP}:{SSH_HPORT}-:22,hostfwd=tcp:{HOSTIP}:{WEB_HPORT}-:443,hostname=qemu",
]
qemu_proc = subprocess.Popen(qemu_cmd)

# Wait for the socket to appear, then fix perms (QEMU runs as root → socket is
# root-owned; socat/zbmc shell need user access).
for _ in range(30):
    if os.path.exists(SOCK):
        subprocess.run(["sudo", "-n", "chmod", "777", SOCK], check=False)
        break
    time.sleep(0.5)
else:
    print("FAIL: serial socket never appeared", flush=True)
    qemu_proc.kill(); sys.exit(1)

# Connect pexpect to the serial socket via socat for bootstrap
child = pexpect.spawn("socat", ["-,raw,echo=0", f"UNIX-CONNECT:{SOCK}"],
                      encoding="utf-8", timeout=240)
child.logfile = open(os.path.join(WD, "x10-console.log"), "w")

child.expect("Please press Enter to activate this console.")
child.sendline("")
child.expect(r"/ #")

def apply_net():
    for cmd in [
        "ip link set eth0 addr 4A:0A:AB:7C:96:2F",
        "ifconfig eth0 10.0.2.15",
        "ifconfig eth0 netmask 255.255.255.0",
        "ifconfig eth0 broadcast 10.0.2.255",
        "ifconfig eth0 up",
        "ip route add 0.0.0.0/0.0.0.0 via 10.0.2.2",
    ]:
        child.sendline(cmd); child.expect(r"/ #")

apply_net()

# RACE FIX: firmware starts udhcpc after our config, clobbers the static IP.
# Wait for udhcpc to give up, then reassert.
try:
    child.expect(r"No lease, forking to background", timeout=90)
    child.sendline(""); child.expect(r"/ #")
    apply_net()
except pexpect.TIMEOUT:
    pass

child.sendline("ifconfig eth0"); child.expect(r"/ #")
if "10.0.2.15" not in child.before:
    print("NET_CONFIG_FAILED eth0 lost its IP after udhcpc", flush=True)
    qemu_proc.kill(); sys.exit(1)

# Patch SSH: replace SMASH-CLP with a real root shell.
# Dropbear hardcodes /SMASH/msh as the login shell (not from /etc/passwd).
# Bind-mount a tiny wrapper over it, then restart dropbear with the correct
# host key paths so new SSH sessions get /bin/ash instead of SMASH-CLP.
for cmd in [
    "cat > /tmp/msh << 'WEOF'\n#!/bin/ash\nexec /bin/ash -l\nWEOF",
    "chmod +x /tmp/msh",
    "mount --bind /tmp/msh /SMASH/msh",
    # Wait for firmware to generate host keys (written on first boot)
    "while [ ! -f /nv/dropbear/dropbear_rsa_host_key ]; do sleep 1; done",
    "killall dropbear",
    "/usr/local/dropbear/sbin/dropbear -p 22"
    " -r /nv/dropbear/dropbear_rsa_host_key"
    " -d /nv/dropbear/dropbear_dss_host_key",
]:
    child.sendline(cmd); child.expect(r"/ #", timeout=30)

# Patch Redfish: bypass OEM license check via LD_PRELOAD.
# index.fcgi (FastCGI Redfish handler) imports license_check() from libipmi.so;
# without a valid OOB license, all Redfish endpoints return 403. Preloading a
# tiny .so that defines license_check() { return 1; } overrides the real one.
# Transfer via printf over serial — BusyBox echo -n is unreliable.
import base64
with open(BYPASS_SO, "rb") as f:
    b64 = base64.b64encode(f.read()).decode()
child.sendline(": > /tmp/lb64"); child.expect(r"/ #", timeout=5)
for i in range(0, len(b64), 512):
    chunk = b64[i:i+512]
    child.sendline(f"printf '%s' '{chunk}' >> /tmp/lb64"); child.expect(r"/ #", timeout=5)
for cmd in [
    "base64 -d < /tmp/lb64 > /tmp/license_bypass.so && rm /tmp/lb64",
    "chmod 644 /tmp/license_bypass.so",
    "cat > /tmp/index-wrapper.sh << 'WEOF'\n#!/bin/ash\n"
    "export LD_PRELOAD=/tmp/license_bypass.so\nexec /bin/index.fcgi\nWEOF",
    "chmod +x /tmp/index-wrapper.sh",
    "cp /usr/local/httpd/lighttpd.conf /tmp/lighttpd.conf",
    "sed -i 's|/bin/index.fcgi|/tmp/index-wrapper.sh|g' /tmp/lighttpd.conf",
    "killall lighttpd 2>/dev/null; killall index.fcgi 2>/dev/null; sleep 1",
    "/usr/local/httpd/sbin/lighttpd -f /tmp/lighttpd.conf -m /usr/local/httpd/lib/",
]:
    child.sendline(cmd); child.expect(r"/ #", timeout=10)

# Bootstrap done — disconnect socat, freeing the socket for interactive use.
child.close()
print("NET_CONFIGURED", flush=True)

# Hold until qemu exits (killed externally via `zbmc stop`).
try:
    qemu_proc.wait()
except KeyboardInterrupt:
    qemu_proc.kill()
