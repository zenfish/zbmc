#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
box="$repo/boxes/irmc-fujitsu"

bash -n "$box/build.sh"
bash -n "$box/boot.sh"
bash -n "$box/zbmc.box"

grep -Fxq 'ZBMC_QEMU_MAJOR=11' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=ast2600-evb' "$box/zbmc.box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES="webui"' "$box/zbmc.box"
grep -Fxq 'ZBMC_DISABLED_SERVICES="redfish"' "$box/zbmc.box"
grep -Fxq 'ZBMC_READY_DEADLINE=900' "$box/zbmc.box"
grep -Fxq "ZBMC_READY_GREP='INIT: Entering runlevel: 3'" "$box/zbmc.box"
grep -Fq 'source_flash_sha256=89dd885694ebc86af29e900f04e22d4b63998ac35055e18c86ba96d6016ce2ed' "$box/build.sh"

grep -Fq -- '-nic user -nic user' "$box/boot.sh"
grep -Fq -- '-nic "user,net=192.168.2.0/24' "$box/boot.sh"
grep -Fq 'hostfwd=udp:$IP:$IPMI_PORT-:623' "$box/boot.sh"
grep -Fq 'hostfwd=tcp:$IP:$HTTPS_PORT-:443' "$box/boot.sh"
grep -Fq 'irmc_no_redfish' "$box/boot.sh"
grep -Fq 'initramfs-shell.cpio.gz' "$box/boot.sh"
grep -Fq 'irmc_diag_shell' "$box/boot.sh"
grep -Fq 'irmc_diag_root' "$box/boot.sh"
grep -Fq '/newroot/usr/local/bin/remman' "$box/build.sh"
grep -Fq "busybox echo 'exec /bin/sh -i'" "$box/build.sh"
grep -Fq 'getty -n -l /usr/local/bin/remman' "$box/build.sh"

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

grep -Fq 'RMCP+ IPMI starts but does not answer' "$box/index.html"
grep -Eq '^irmc-fujitsu[[:space:]]+10\.0\.6\.68$' "$repo/zhosts.txt"
grep -Fq 'irmc-fujitsu' "$repo/qemu/recipes/qemu-11-arm.sh"
