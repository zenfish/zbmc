#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

command=$("$repo/tools/zbmc-connectivity" guest-command 10.0.0.24 45690 probe.txt)
grep -Fq 'ping -c 3 -W 2 10.0.0.24' <<<"$command"
grep -Fq 'busybox wget -T 5 -O /dev/null http://10.0.0.24:45690/probe.txt' <<<"$command"

python3 - "$tmp/serial.sock" <<'PY' &
import socket, sys
s = socket.socket(socket.AF_UNIX)
s.bind(sys.argv[1])
s.listen(1)
c, _ = s.accept()
command = c.recv(65536)
c.sendall(b"echo " + command + b"\r\nRESULT\r\nZBMC_TEST_END\r\n")
c.close()
PY
server=$!
for _ in 1 2 3 4 5; do [ -S "$tmp/serial.sock" ] && break; sleep 0.1; done
printf 'echo test; echo ZBMC_TEST_END\n' >"$tmp/commands"
"$repo/tools/zbmc-serial-capture" "$tmp/serial.sock" "$tmp/commands" "$tmp/transcript" ZBMC_TEST_END --timeout 3
wait "$server"
grep -Fq RESULT "$tmp/transcript"

: >"$tmp/console.log"
python3 - "$tmp/serial-log.sock" "$tmp/console.log" <<'PY' &
import socket, sys
s = socket.socket(socket.AF_UNIX)
s.bind(sys.argv[1])
s.listen(1)
c, _ = s.accept()
c.recv(65536)
c.sendall(b"firmware noise\n" * 65536)
with open(sys.argv[2], "ab") as log:
    log.write(b"LOG_RESULT\nZBMC_LOG_END\n")
c.close()
PY
server=$!
for _ in 1 2 3 4 5; do [ -S "$tmp/serial-log.sock" ] && break; sleep 0.1; done
"$repo/tools/zbmc-serial-capture" "$tmp/serial-log.sock" "$tmp/commands" \
  "$tmp/log-transcript" ZBMC_LOG_END --console-log "$tmp/console.log" --timeout 5
wait "$server"
grep -Fq LOG_RESULT "$tmp/log-transcript"

echo "connectivity tools: PASS"
