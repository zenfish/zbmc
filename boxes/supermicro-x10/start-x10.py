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
import sys, os, time, subprocess, signal, pexpect, json, uuid
from datetime import datetime, timezone

SELF = os.path.dirname(os.path.abspath(__file__))                                # box scripts dir
WD = os.environ.get("WD", SELF)                                                 # artifacts/logs
PACKET_DIR = os.environ.get("X10_PACKET_DIR", WD)
RUN_ID = (datetime.now(timezone.utc).isoformat(timespec="milliseconds")
          .replace("+00:00", "Z") + "_" + str(uuid.uuid4()))
MASTER = os.environ.get("X10_MASTER", os.path.join(WD, "x10-master.flash"))     # firmware seed
BYPASS_SO = os.path.join(SELF, "license_bypass.so")                              # LD_PRELOAD shim
RUN = os.path.join(WD, "x10-run.flash")
SOCK = os.path.join(WD, "x10-serial.sock")
CONSOLE_LOG = os.environ.get("ZBMC_CONSOLE_LOG", os.path.join(WD, "x10-console.log"))
QMP_SOCK = os.path.join(WD, "x10-qmp.sock")
GDB_SOCK = os.path.join(WD, "x10-gdb.sock")
TRACE_FILE = os.path.join(PACKET_DIR, f"{RUN_ID}-qemu-trace.bin")
DEBUG_FILE = os.path.join(PACKET_DIR, f"{RUN_ID}-qemu-debug.log")
RUN_MANIFEST = os.path.join(PACKET_DIR, f"{RUN_ID}-manifest.json")
HOSTIP   = os.environ.get("X10_HOSTIP", os.environ.get("ZBMC_IP", "10.0.8.10"))
HOSTPORT = os.environ.get("X10_HOSTPORT", "623")
SSH_HPORT = os.environ.get("X10_SSH_PORT", "22")
WEB_HPORT = os.environ.get("X10_WEB_PORT", "443")
NET_MODE = os.environ.get("X10_NET_MODE", "user")
TAP = os.environ.get("X10_TAP", "ztap-x10")
AUX_TAP = os.environ.get("X10_AUX_TAP", "ztap-x10-aux")
GUEST_IP = os.environ.get("X10_GUEST_IP", HOSTIP if NET_MODE == "direct" else "10.0.2.15")
NETMASK = os.environ.get("X10_NETMASK", "255.0.0.0" if NET_MODE == "direct" else "255.255.255.0")
GATEWAY = os.environ.get("X10_GATEWAY", "10.0.0.1" if NET_MODE == "direct" else "10.0.2.2")
IFACE = os.environ.get("X10_IFACE", "eth1" if NET_MODE == "direct" else "eth0")
import shutil as _sh
QEMU     = os.environ.get("X10_QEMU",
           _sh.which("qemu-system-arm") or "/opt/homebrew/bin/qemu-system-arm")
QEMU_PLUGIN = os.environ.get("X10_QEMU_PLUGIN", "")
FTGMAC_GUARD = os.environ.get("X10_FTGMAC_GUARD", "")
QEMU_DEBUG = os.environ.get("X10_QEMU_DEBUG", "guest_errors,unimp,cpu_reset")

_sh.copyfile(MASTER, RUN)
os.makedirs(PACKET_DIR, exist_ok=True)

# Clean stale socket
if os.path.exists(SOCK):
    os.unlink(SOCK)
if os.path.exists(QMP_SOCK):
    os.unlink(QMP_SOCK)
if os.path.exists(GDB_SOCK):
    os.unlink(GDB_SOCK)

# Launch QEMU with serial on a UNIX socket (not -nographic, which ties serial
# to stdio). -display none suppresses the GUI; -monitor none avoids the monitor
# prompt on stdio.
qemu_cmd = [
    "sudo", "-n", QEMU,
    "-m", "128", "-M", "supermicrox11-bmc",
    "-display", "none", "-monitor", "none",
    "-qmp", f"unix:{QMP_SOCK},server=on,wait=off",
    "-gdb", f"unix:{GDB_SOCK},server=on,wait=off",
    "-perfmap",
    "-d", QEMU_DEBUG,
    "-D", DEBUG_FILE,
    "-trace", "enable=ftgmac100_*",
    "-trace", f"file={TRACE_FILE}",
    "-chardev", f"socket,id=ser0,path={SOCK},server=on,wait=off,logfile={CONSOLE_LOG},logappend=off",
    "-serial", "chardev:ser0",
    "-drive", f"file={RUN},format=raw,if=mtd",
]
if QEMU_PLUGIN:
    qemu_cmd += ["-plugin", QEMU_PLUGIN]
if FTGMAC_GUARD:
    qemu_cmd += ["-global", f"ftgmac100.guard={FTGMAC_GUARD}"]
if NET_MODE == "direct":
    qemu_cmd += [
        # Bridge both AST2400 MACs so controller ordering cannot silently put
        # the guest's configured interface on a translated backend.
        "-netdev", f"tap,id=bmcnet,ifname={TAP},script=no,downscript=no",
        "-net", "nic,netdev=bmcnet",
        "-netdev", f"tap,id=bmcaux,ifname={AUX_TAP},script=no,downscript=no",
        "-net", "nic,netdev=bmcaux",
        "-object", f"filter-dump,id=netcap,netdev=bmcnet,file={os.path.join(PACKET_DIR, RUN_ID + '-qemu-primary.pcap')}",
        "-object", f"filter-dump,id=auxcap,netdev=bmcaux,file={os.path.join(PACKET_DIR, RUN_ID + '-qemu-aux.pcap')}",
    ]
else:
    qemu_cmd += [
        "-net", "nic",
        "-net", f"user,hostfwd=udp:{HOSTIP}:{HOSTPORT}-:623,hostfwd=tcp:{HOSTIP}:{SSH_HPORT}-:22,hostfwd=tcp:{HOSTIP}:{WEB_HPORT}-:443,hostname=qemu",
    ]
qemu_proc = subprocess.Popen(qemu_cmd)
with open(RUN_MANIFEST, "w", encoding="utf-8") as manifest:
    json.dump({
        "run_id": RUN_ID,
        "started_utc": RUN_ID.split("_", 1)[0],
        "qemu_pid": qemu_proc.pid,
        "qemu": QEMU,
        "qemu_command": qemu_cmd,
        "work_dir": WD,
        "packet_dir": PACKET_DIR,
    }, manifest, indent=2)
    manifest.write("\n")
print(f"RUN_ID {RUN_ID}", flush=True)

# Wait for the socket to appear, then fix perms (QEMU runs as root → socket is
# root-owned; socat/zbmc shell need user access).
for _ in range(30):
    if os.path.exists(SOCK):
        for control_sock in (SOCK, QMP_SOCK, GDB_SOCK):
            subprocess.run(["sudo", "-n", "chmod", "777", control_sock], check=False)
        break
    time.sleep(0.5)
else:
    print("FAIL: serial socket never appeared", flush=True)
    qemu_proc.kill(); sys.exit(1)

# Connect pexpect to the serial socket via socat for bootstrap
child = pexpect.spawn("socat", ["-,raw,echo=0", f"UNIX-CONNECT:{SOCK}"],
                      encoding="utf-8", timeout=240)

child.expect("Please press Enter to activate this console.")
child.sendline("")
child.expect(r"/ #")

def apply_net():
    for cmd in [
        f"ip link set {IFACE} addr 4A:0A:AB:7C:96:2F",
        f"ifconfig {IFACE} {GUEST_IP}",
        f"ifconfig {IFACE} netmask {NETMASK}",
        f"ifconfig {IFACE} up",
        "ip route del default 2>/dev/null || true",
        f"ip route add default via {GATEWAY}",
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

child.sendline(f"ifconfig {IFACE}"); child.expect(r"/ #")
if GUEST_IP not in child.before:
    print(f"NET_CONFIG_FAILED {IFACE} lost its IP after udhcpc", flush=True)
    qemu_proc.kill(); sys.exit(1)

# Patch SSH: replace SMASH-CLP with a real root shell.
# Dropbear hardcodes /SMASH/msh as the login shell (not from /etc/passwd).
# Bind-mount a tiny wrapper over it, then restart dropbear with the correct
# host key paths so new SSH sessions get /bin/ash instead of SMASH-CLP.
for cmd in [
    "cat > /tmp/msh << 'WEOF'\n#!/bin/ash\nexec /bin/ash -l\nWEOF",
    "chmod +x /tmp/msh",
    "mount --bind /tmp/msh /SMASH/msh",
]:
    child.sendline(cmd); child.expect(r"/ #", timeout=30)

# Firmware creates RSA and DSS keys asynchronously, then starts its own Dropbear.
# Waiting for RSA alone races the later DSS/start task: our replacement can lose
# bind(22), exit, and leave no listener after the firmware instance disappears.
child.sendline("while [ ! -f /nv/dropbear/dropbear_rsa_host_key ] || "
               "[ ! -f /nv/dropbear/dropbear_dss_host_key ]; do sleep 1; done")
child.expect(r"/ #", timeout=90)
child.sendline("i=0; while netstat -lnt 2>/dev/null | grep -q ':22 '; do "
               "killall dropbear 2>/dev/null; sleep 1; i=$((i+1)); "
               "[ $i -ge 15 ] && break; done")
child.expect(r"/ #", timeout=20)
child.sendline("/usr/local/dropbear/sbin/dropbear -p 22"
               " -r /nv/dropbear/dropbear_rsa_host_key"
               " -d /nv/dropbear/dropbear_dss_host_key")
child.expect(r"/ #", timeout=10)
child.sendline("sleep 1; netstat -lnt 2>/dev/null | grep -q ':22 ' && "
               "echo SSH_LISTENING || echo SSH_START_FAILED")
child.expect(r"/ #", timeout=10)
if "SSH_LISTENING" not in child.before:
    print("SSH_START_FAILED no listener on guest port 22", flush=True)
    qemu_proc.kill(); sys.exit(1)

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

# LanNotifier/udhcpc can run again late and zero both MACs after every service
# briefly became reachable. Retire that dynamic path, then make the final static
# assignment authoritative before releasing the bootstrap console.
child.sendline("killall udhcpc 2>/dev/null; killall LanNotifier 2>/dev/null; sleep 1")
child.expect(r"/ #", timeout=10)
apply_net()
child.sendline(f"ifconfig {IFACE}"); child.expect(r"/ #", timeout=10)
if GUEST_IP not in child.before:
    print(f"NET_CONFIG_FAILED final assignment missing on {IFACE}", flush=True)
    qemu_proc.kill(); sys.exit(1)

# Preserve both a bounded local ring and a Debby-side copy when the legacy
# BusyBox logging tools are present.  The remote stream is supplemental: it can
# disappear with the network, while the guest ring remains available on serial.
child.sendline("if [ -x /sbin/syslogd ]; then killall syslogd 2>/dev/null; /sbin/syslogd -C256 -l 8 -L -R 10.0.0.24:5514 2>/dev/null || /sbin/syslogd -C256 -l 8 -L 2>/dev/null; fi")
child.expect(r"/ #", timeout=10)
child.sendline("if command -v klogd >/dev/null 2>&1; then killall klogd 2>/dev/null; klogd -c 8 2>/dev/null; fi; logger -p daemon.debug 'ZBMC instrumentation logging enabled'")
child.expect(r"/ #", timeout=10)

# Bootstrap done — disconnect socat, freeing the socket for interactive use.
child.close()
print("NET_CONFIGURED", flush=True)
ready_file = os.environ.get("X10_READY_FILE")
if ready_file:
    with open(ready_file, "w", encoding="ascii") as f:
        f.write(f"{qemu_proc.pid}\n")

# Hold until qemu exits (killed externally via `zbmc stop`).
try:
    qemu_proc.wait()
except KeyboardInterrupt:
    qemu_proc.kill()
