#!/usr/bin/env bash
# Detached launcher for the X10 oracle. nohup the pexpect driver (holds qemu as
# its child + fixes guest networking), wait for NET_CONFIGURED (IPMI reachable on
# 10.0.8.10:623/udp), then print the qemu pid. Zoo-standard model like x14: qemu
# runs under sudo and binds the selected Linux loopback address on privileged port 623.
# The loopback alias and sudo context are prepared by the box's zbmc_boot before this runs.
# Idempotent: no-op if this box's qemu is already up.
set -u
SELF="$(cd "$(dirname "$0")" && pwd)"   # scripts live here (repo box dir)
WD="${WD:-$SELF}"; export WD          # artifacts/logs (env override; default self)
IP="${ZBMC_IP:-10.0.8.10}"; export X10_HOSTIP="$IP"
LOG="$WD/x10-start.log"; mkdir -p "$WD"

MATCH="hostfwd=udp:$IP:623-:623"
qemu_pid() {
  local p
  p=$(pgrep -f "^[^ ]*/qemu-system-arm .*$MATCH" | head -1)
  [ -n "$p" ] || return 1
  echo "$p"
}
if qemu_pid >/dev/null 2>&1; then
  qemu_pid; exit 0
fi

: > "$LOG"
READY="$WD/x10-ready.$$"
rm -f "$READY"
export X10_READY_FILE="$READY"
trap 'rm -f "$READY"' EXIT
nohup python3 "$SELF/start-x10.py" >>"$LOG" 2>&1 &
echo "$!" >"$WD/x10-driver.pid"
sleep 1
if [ "${X10_LAUNCH_ONLY:-0}" = 1 ]; then
  for _ in $(seq 1 20); do
    if qemu_pid >/dev/null 2>&1; then qemu_pid; exit 0; fi
    sleep 0.25
  done
  echo "x10 qemu did not launch — see $LOG" >&2
  exit 1
fi
for _ in $(seq 1 60); do
  if [ -s "$READY" ]; then
    qemu_pid; exit 0
  fi
  qemu_pid >/dev/null 2>&1 || { echo "x10 qemu died — see $LOG" >&2; exit 1; }
  sleep 3
done
echo "x10 boot timeout — see $LOG" >&2; exit 1
