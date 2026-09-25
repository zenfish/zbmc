#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
box="$repo/boxes/irmc-fujitsu"

bash -n "$box/build.sh"
bash -n "$box/boot.sh"
bash -n "$box/zbmc.box"

grep -Fxq 'ZBMC_QEMU_MAJOR=11' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=ast2600-evb' "$box/zbmc.box"
grep -Fxq 'ZBMC_NETWORK_MODE=tap' "$box/zbmc.box"
grep -Fxq 'ZBMC_TAP=ztap-irmc2' "$box/zbmc.box"
grep -Fxq 'ZBMC_MAC=52:54:00:fa:42:02' "$box/zbmc.box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES="ipmi redfish webui"' "$box/zbmc.box"
! grep -Fq 'ZBMC_DISABLED_SERVICES=' "$box/zbmc.box"
grep -Fxq 'ZBMC_READY_DEADLINE=1800' "$box/zbmc.box"
grep -Fxq "ZBMC_READY_GREP='Entering runlevel: 3'" "$box/zbmc.box"
grep -Fq 'source_flash_sha256=89dd885694ebc86af29e900f04e22d4b63998ac35055e18c86ba96d6016ce2ed' "$box/build.sh"
grep -Fq 'WD="$(cd "$WD" && pwd)"' "$box/build.sh"

grep -Fq 'tap,id=net2,ifname=$TAP2,script=no,downscript=no' "$box/boot.sh"
grep -Fq 'system-redfish.dtb' "$box/boot.sh"
grep -Fq 'file=$WD/flash64.img,format=raw,if=none,id=fmc1,snapshot=on' "$box/boot.sh"
grep -Fq 'w25q512jv,bus=ssi.0,cs=1,drive=fmc1' "$box/boot.sh"
grep -Fq 'zbmc_ip=$IP zbmc_gateway=10.0.0.1' "$box/boot.sh"
grep -Fq 'ZBMC_TAP_NETWORK_READY $zbmc_ip' "$box/build.sh"
grep -Fq 'busybox ifconfig eth0 "$zbmc_ip" netmask 255.0.0.0 up' "$box/build.sh"
! grep -Fq 'zbmc-configure-serial-ip.py' "$box/zbmc.box"
python3 - "$box/build.sh" <<'PY'
import ast
import pathlib
import re
import subprocess
import sys

text = pathlib.Path(sys.argv[1]).read_text()
match = re.search(r'addition = (""".*?""")', text, re.DOTALL)
assert match, "missing derived initramfs addition"
addition = ast.literal_eval(match.group(1))
subprocess.run(["bash", "-n"], input=addition, text=True, check=True)
sed_match = re.search(r"busybox sed '([^']*IPMIMain[^']*)'", addition)
assert sed_match, "missing IPMIMain startup transformation"
source = "    /usr/local/bin/IPMIMain --daemonize --reg-with-procmgr\n"
result = subprocess.run(
    ["sed", sed_match.group(1)], input=source, text=True, check=True,
    capture_output=True,
)
assert result.stdout == (
    "    irmc_ipmi_prep || exit 1; "
    "irmc_ipmi_trace_listener; "
    "/usr/local/bin/IPMIMain --daemonize --reg-with-procmgr\n"
), result.stdout
PY
grep -Fq 'irmc_redfish' "$box/boot.sh"
! grep -Fq 'irmc_no_redfish' "$box/boot.sh"
grep -Fq 'initramfs-shell.cpio.gz' "$box/boot.sh"
grep -Fq 'irmc_diag_shell' "$box/boot.sh"
grep -Fq 'irmc_diag_root' "$box/boot.sh"
grep -Fq 'irmc_diag_ipmi' "$box/boot.sh"
grep -Fq 'irmc_trace_ipmi' "$box/boot.sh"
grep -Fq '/newroot/usr/local/bin/remman' "$box/build.sh"
grep -Fq "busybox echo 'exec /bin/sh -i'" "$box/build.sh"
grep -Fq 'getty -n -l /usr/local/bin/remman' "$box/build.sh"
grep -Fq 'AMI_DYNAMIC_LAN_IFC_SUPPORT=1' "$box/build.sh"
grep -Fq '[Dynamic_IFC_Support_Cfg]' "$box/build.sh"
grep -Fq '[LANIfcConfig/LanIfcConfig/0]' "$box/build.sh"
grep -Fq 'lancfg=/conf/BMC1/lancfg0.ini' "$box/build.sh"
grep -Fq 'IPAddrSrc=1' "$box/build.sh"
grep -Fq 'IPv4_Enable=1' "$box/build.sh"
grep -Fq 'IPv6_Enable=0' "$box/build.sh"
grep -Fq 'SubNetMask/0=255' "$box/build.sh"
grep -Fq 'LAN channel enabled with static IPv4 $static_ip/8 and IPv6 disabled' "$box/build.sh"
grep -Fq 'section && /^Enabled=0$/' "$box/build.sh"
grep -Fq 'section && /^Up_Status=0$/' "$box/build.sh"
grep -Fq 'rm -f /tmp/BMC1/IPMIConfig.dat' "$box/build.sh"
grep -Fq 'irmc_ipmi_prep || exit 1' "$box/build.sh"
grep -Fq 'ZBMC_IPMI_LISTENER' "$box/build.sh"
grep -Fq '/ahb/spi@1e620000/flash@1 status okay' "$box/build.sh"
grep -Fq '/ahb/mtdconcat@0 devices 5 6' "$box/build.sh"
grep -Fq '/ahb/mtdconcat@0/partitions compatible ami,spx-fmh' "$box/build.sh"
grep -Fq 'bs=65536 skip=574 count=4' "$box/build.sh"
grep -Fq '/newroot/usr/local/platform' "$box/build.sh"
grep -Fq 'embedded platform SquashFS mounted' "$box/build.sh"
grep -Fq 'zbmc_redfish_health()' "$box/zbmc.box"
grep -Fq 'PasswordChangeRequired' "$box/zbmc.box"

tmp=$(mktemp -d)
trap 'rmdir "$tmp"' EXIT
python3 - "$box" "$tmp" <<'PY'
import os
import pty
import select
import socket
import sys
import time

box, tmp = sys.argv[1:]
socket_path = os.path.join(tmp, "serial.sock")
listener = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
listener.bind(socket_path)
listener.listen(1)
listener.settimeout(3)

pid, terminal = pty.fork()
if pid == 0:
    env = os.environ | {"BOX": box, "TEST_SOCK": socket_path}
    command = '_zbmc_resolve_ip() { echo 127.0.0.1; }; . "$BOX/zbmc.box"; SOCK="$TEST_SOCK"; zbmc_console --nostderr'
    os.execvpe("bash", ("bash", "-c", command), env)

connection, _ = listener.accept()
connection.sendall(
    b"prompt: ###(ESPI):haGetEspiPCHRTC(RX) : ERROR: retry count over\n"
    b"[285 : 343 WARNING][IPMBIfc.c:752]IPMBIfc.c : Error sending IPMB packet to Slave 0x16\n"
    b"GetRTCTimeViaESPI L.231: ERROR: retry count exceeded(ret:-1)\n"
    b"bt:8325: /usr/local/bin/FTS_PCIeFunction1(main+0xc4) [0x13e7c]\n"
    b"[8325 : 8325 WARNING][irmcPCIeSignalHndlr.c:88]  Received SIGSEGV\n\n"
    b"Initialize power control\n"
    b"Node Manager SlaveAddr: 0x2C\n"
    b"pwcpDeviceInit()\n"
    b"fts_NM_errorRecovery(): Start simple error recovery. Error flags: 0008\n\n"
    b"fts_NM_RecvGetDeviceId(): GetDeviceId CC: 0xC0\n\n"
    b"/conf # ls /conf/\x1b[Ju[285 : 405 CRITICAL][libipmi_uds_session.c:618]Send_RAW_IPMI2_0_UDS_Command: NetFN and command mismatched NetFnLUN : 06 (expected : 0A), Command : 01 (expected : 10)\r\n"
    b"/conf # ls /conf/user_home/\x1b[J[8932 : 8932 CRITICAL][libipmi_uds_session.c:629]Send_RAW_IPMI2_0_UDS_Command: Response too big: 5 (expected max: 1). NetfnLUN: 00, command: 01.\r\n"
    b"one-off error remains visible\n/conf # "
)

output = bytearray()
deadline = time.monotonic() + 3
while b"/conf # " not in output and time.monotonic() < deadline:
    readable, _, _ = select.select((terminal,), (), (), 0.1)
    if readable:
        output += os.read(terminal, 4096)

assert b"prompt: " in output, output
assert b"one-off error remains visible" in output, output
assert b"/conf # " in output, output
assert b"retry count over" not in output, output
assert b"Error sending IPMB packet" not in output, output
assert b"retry count exceeded" not in output, output
assert b"FTS_PCIeFunction1" not in output, output
assert b"Received SIGSEGV" not in output, output
assert b"Initialize power control" not in output, output
assert b"Node Manager" not in output, output
assert b"fts_NM_" not in output, output
assert b"NetFN and command mismatched" not in output, output
assert b"Response too big" not in output, output
assert b"\x1b[Ju" in output, output

os.write(terminal, b"\x1d")
os.waitpid(pid, 0)
connection.close()
listener.close()
os.close(terminal)
os.unlink(socket_path)
PY

grep -Fq 'Authenticated RMCP+ IPMI and the preserved Fujitsu HTTPS Web UI both answer' "$box/index.html"
grep -Fq 'href="redfish-path.html"' "$box/index.html"
grep -Fq '/var/tmp/RedfishServer.sock' "$box/redfish-path.html"
grep -Fq '/var/UDSocket' "$box/redfish-path.html"
grep -Fq '/var/tmp/redis.sock' "$box/redfish-path.html"
grep -Fq '274/274' "$box/redfish-path.html"
grep -Fq 'exactly 280 successful Redis connections' "$box/redfish-path.html"
grep -Fq '71962ae0-3955-5c2a-a449-4ae8445e8e15' "$box/redfish-path.html"
grep -Eq '^irmc-fujitsu[[:space:]]+10\.0\.6\.68$' "$repo/zhosts.txt"
grep -Fq 'irmc-fujitsu' "$repo/qemu/recipes/qemu-11-arm.sh"
