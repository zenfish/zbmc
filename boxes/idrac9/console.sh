#!/usr/bin/env bash
# console.sh — attach to the virtual iDRAC9's root shell on ttyS1 (console-shell.service).
# THE way to drive a checkpoint-RESTORED box when host network doesn't survive restore: gives a root
# /bin/sh inside the guest to run racadm, `curl -k https://127.0.0.1/redfish/v1/Managers -u root:Calvin123#`
# (200 from inside), poke IPMI, etc. Also works on a live box. Press Enter for a prompt. Detach: Ctrl-] .
# RUN: ./console.sh
set -euo pipefail
SOCK=/tmp/vbmc-idrac9-ttyS1.sock
[ -S "$SOCK" ] || { echo "no ttyS1 socket ($SOCK) — is the box running (run-p6*.sh)?"; exit 1; }
if command -v socat >/dev/null; then
  exec socat -,raw,echo=0,escape=0x1d "unix-connect:$SOCK"     # Ctrl-] detaches
else
  exec nc -U "$SOCK"
fi
