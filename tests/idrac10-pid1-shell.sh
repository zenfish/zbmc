#!/usr/bin/env bash
set -euo pipefail

script="$(dirname "$0")/../boxes/idrac10/boot-fullfw-guest.sh"
box="$(dirname "$0")/../boxes/idrac10/zbmc.box"
driver="$(dirname "$0")/../boxes/idrac10/boot-idrac10.exp"
sh -n "$script"
grep -q 'PasswordAuthentication yes' "$script"
tail -n 12 "$script" | grep -q '^while :; do$'
tail -n 12 "$script" | grep -q '^    /bin/sh || true$'
if tail -n 12 "$script" | grep -q '^exit '; then
    echo "boot script still exits to PID 1" >&2
    exit 1
fi
grep -A5 '^zbmc_ssh()' "$box" | grep -q 'sshpass'
grep -A5 '^zbmc_console()' "$box" | grep -q 'socat'
! grep -q 'pkill .*fullfw' "$driver"

echo "idrac10 access paths and PID 1 shell supervision: PASS"
