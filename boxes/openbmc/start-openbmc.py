#!/usr/bin/env python3
"""Launch vanilla OpenBMC on the direct zbmc bridge and configure its IP."""
import json, os, pexpect, signal, subprocess, sys, time

wd = os.environ["WD"]
flash = os.environ["OPENBMC_FLASH"]
ip = os.environ.get("ZBMC_IP", "10.0.7.10")
tap = os.environ.get("OPENBMC_TAP", "ztap-openbmc")
qemu = os.environ.get("OPENBMC_QEMU", "/home/zen/opt/qemu-11/bin/qemu-system-arm")
sock = os.path.join(wd, "serial.sock")
qmp = os.path.join(wd, "qmp.sock")
log = os.path.join(wd, "console.log")
trace = os.path.join(wd, "qemu-trace.bin")
debug = os.path.join(wd, "qemu-debug.log")
for p in (sock, qmp):
    try: os.unlink(p)
    except FileNotFoundError: pass
os.makedirs(wd, exist_ok=True)

cmd = ["sudo", "-n", qemu, "-M", "ast2600-evb", "-smp", "2", "-m", "1G",
       "-display", "none", "-monitor", "none",
       "-qmp", f"unix:{qmp},server=on,wait=off", "-d", "guest_errors,unimp,cpu_reset",
       "-D", debug, "-trace", "enable=ftgmac100_*", "-trace", f"file={trace}",
       "-drive", f"file={flash},format=raw,if=mtd,snapshot=on",
       "-chardev", f"socket,id=ser0,path={sock},server=on,wait=off", "-serial", "chardev:ser0",
       "-netdev", f"tap,id=bmcnet,ifname={tap},script=no,downscript=no",
       "-net", "nic,netdev=bmcnet"]
q = subprocess.Popen(cmd, stdout=open(log, "w"), stderr=subprocess.STDOUT)
with open(os.path.join(wd, "qemu-command.txt"), "w") as f: f.write(" ".join(cmd) + "\n")
with open(os.path.join(wd, "launcher.pid"), "w") as f: f.write(str(os.getpid()) + "\n")
for _ in range(120):
    if os.path.exists(sock): break
    if q.poll() is not None: raise SystemExit("QEMU exited before serial socket")
    time.sleep(.5)
else: raise SystemExit("serial socket timeout")

child = pexpect.spawn("socat", ["-", "raw,echo=0", f"UNIX-CONNECT:{sock}"], encoding="utf-8", timeout=30)
child.logfile = open(log, "a")
try:
    child.expect([r"login:", r"/#", r"# ", r"root@.*:~#", pexpect.TIMEOUT], timeout=180)
    if "login:" in child.after:
        child.sendline("root"); child.expect([r"Password:", r"password:"]); child.sendline("0penBmc")
        child.expect([r"/#", r"# ", r"root@.*:~#"], timeout=30)
    for line in [
        "ip link set eth0 up",
        "ip addr flush dev eth0",
        f"ip addr add {ip}/8 dev eth0",
        "ip route replace default via 10.0.0.1",
        "ip addr show dev eth0",
    ]:
        child.sendline(line); child.expect([r"/#", r"# ", r"root@.*:~#"], timeout=20)
    child.sendline("echo ZBMC_NETWORK_CONFIGURED"); child.expect("ZBMC_NETWORK_CONFIGURED", timeout=10)
finally:
    child.close(force=True)
q.wait()
