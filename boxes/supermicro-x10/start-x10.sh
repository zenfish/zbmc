#!/usr/bin/env bash
# Detached launcher for the X10 oracle. nohup the pexpect driver (holds qemu as
# its child + fixes guest networking), wait for NET_CONFIGURED (IPMI reachable on
# 10.0.8.10:623/udp), then print the qemu pid. Zoo-standard model like x14: qemu
# runs under sudo, binds the lo0-alias IP 10.0.8.10 on privileged port 623.
# The lo0 alias + sudo timestamp are primed by the box's zbmc_boot before this runs.
# Idempotent: no-op if this box's qemu is already up.
set -u
SELF="$(cd "$(dirname "$0")" && pwd)"   # scripts live here (repo box dir)
WD="${WD:-$SELF}"; export WD          # artifacts/logs (env override; default self)
LOG="$WD/x10-start.log"; mkdir -p "$WD"

if pgrep -f "hostfwd=udp:10.0.8.10:623-:623" >/dev/null 2>&1; then
  pgrep -f "hostfwd=udp:10.0.8.10:623-:623" | head -1; exit 0
fi

: > "$LOG"
nohup python3 "$SELF/start-x10.py" >>"$LOG" 2>&1 &
for _ in $(seq 1 60); do
  if grep -q NET_CONFIGURED "$LOG" 2>/dev/null; then
    pgrep -f "hostfwd=udp:10.0.8.10:623-:623" | head -1; exit 0
  fi
  pgrep -f supermicrox11-bmc >/dev/null 2>&1 || { echo "x10 qemu died — see $LOG" >&2; exit 1; }
  sleep 3
done
echo "x10 boot timeout — see $LOG" >&2; exit 1
