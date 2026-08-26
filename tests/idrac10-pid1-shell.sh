#!/usr/bin/env bash
set -euo pipefail

script="$(dirname "$0")/../boxes/idrac10/boot-fullfw-guest.sh"
sh -n "$script"
tail -n 12 "$script" | grep -q '^while :; do$'
tail -n 12 "$script" | grep -q '^    /bin/sh || true$'
if tail -n 12 "$script" | grep -q '^exit '; then
    echo "boot script still exits to PID 1" >&2
    exit 1
fi

echo "idrac10 PID 1 shell supervision: PASS"
