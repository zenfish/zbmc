#!/usr/bin/env python3
"""Durable X10 BMC boot driver (Supermicro X10 / ASPEED AST2400, FW 3.93).

Boots the 32MB flash under qemu -M supermicrox11-bmc, then drives the serial
console (per trouble.org/python-shim-over-qemu-to-startup-bmc) to fix networking:
the firmware zeroes its MAC (no FRU/EEPROM in a flat image) and fails to bond
eth0 -> bond0, so DHCP never leases. We press Enter to the root console, set a
valid MAC, assign the qemu user-net static IP, and add the default route.

Prints NET_CONFIGURED when 10.0.8.10:623/udp reaches the guest IPMI, then holds
qemu alive (child EOF). Kill the qemu (pkill -f supermicrox11-bmc) to stop.

Why this box exists: it offers IPMI 2.0 cipher suites 0-14 (incl. the RC4/MD5
suites 4,5,9-14 that modern firmware dropped) — the authorized local oracle for
verifying zipmi's MD5-128 + xRC4 implementations.
"""
import sys, os, pexpect

WD = os.environ.get("WD", os.path.dirname(os.path.abspath(__file__)))   # artifacts/logs
MASTER = os.environ.get("X10_MASTER", os.path.join(WD, "x10-master.flash"))     # firmware seed
RUN = os.path.join(WD, "x10-run.flash")
# host IP + port the qemu user-net forwards land on (a lo0 alias); matches the
# zbmc dispatcher's running()/status greps for hostfwd=udp:<IP>:623-:623.
# Zoo-standard model (like x14): qemu runs under sudo and binds the box's real
# lo0-alias IP on the privileged standard port 623 directly. The earlier
# 127.0.0.1:6623 loopback-highport dodge is retired — x14 proves slirp forwards
# fine to a lo0 alias when qemu is root.
HOSTIP   = os.environ.get("X10_HOSTIP", "10.0.8.10")
HOSTPORT = os.environ.get("X10_HOSTPORT", "623")
QEMU     = os.environ.get("X10_QEMU", "/opt/homebrew/bin/qemu-system-arm")
# fresh run-copy each boot so the master stays pristine
import shutil; shutil.copyfile(MASTER, RUN)

# sudo -n: non-interactive; the caller (zbmc_boot / start-x10.sh) primes the sudo
# timestamp via the lo0-alias ifconfig, so this never prompts here (would hang).
child = pexpect.spawn("sudo", [
    "-n", QEMU,
    "-m", "128", "-M", "supermicrox11-bmc", "-nographic",
    "-drive", f"file={RUN},format=raw,if=mtd",
    "-net", "nic",
    "-net", f"user,hostfwd=udp:{HOSTIP}:{HOSTPORT}-:623,hostfwd=tcp:{HOSTIP}:22-:22,hostname=qemu",
], encoding="utf-8", timeout=240)
child.logfile = open(os.path.join(WD, "x10-console.log"), "w")

child.expect("Please press Enter to activate this console.")
child.sendline("")
child.expect(r"/ #")

# Assign the qemu user-net static IP + route. The firmware zeroes eth0's MAC
# (no FRU/EEPROM) and fails eth0->bond0, so DHCP never leases.
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

# RACE FIX: the firmware's own network service starts udhcpc *after* our config
# and flushes eth0 (console shows "enable IPv4 addressing" -> route unreachable
# -> udhcpc leasefail), wiping the static IP -> the IPMI daemon loses its network
# and never answers. Wait for udhcpc to give up, then reassert. This is why the
# box was flaky: whoever won the race (config applied last) had working IPMI.
try:
    child.expect(r"No lease, forking to background", timeout=90)
    child.sendline(""); child.expect(r"/ #")
    apply_net()
except pexpect.TIMEOUT:
    pass  # no udhcpc this boot (nothing clobbered our config) — proceed

# Make NET_CONFIGURED a REAL signal: confirm eth0 still holds 10.0.2.15 before
# declaring ready (else callers poll a dead IPMI for minutes).
child.sendline("ifconfig eth0"); child.expect(r"/ #")
if "10.0.2.15" not in child.before:
    print("NET_CONFIG_FAILED eth0 lost its IP after udhcpc", flush=True)
    sys.exit(1)
print("NET_CONFIGURED", flush=True)
child.expect(pexpect.EOF, timeout=None)
