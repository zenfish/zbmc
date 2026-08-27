#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

PIDF="$tmp/zbmc.pid"
ZBMC_RUN_DIR="$tmp/run"
mkdir -p "$ZBMC_RUN_DIR"
. "$repo/tools/zbmc-runlib"

sleep 30 & pid=$!
trap 'kill "$pid" 2>/dev/null || true; rm -rf "$tmp"' EXIT
! _zr_owns_qemu_pid "$pid"
_zr_record_qemu_pid "$pid"
[ "$(cat "$PIDF")" = "$pid" ]
_zr_owns_qemu_pid "$pid"
printf '%s\n' 'not this process start' >"$ZBMC_RUN_DIR/qemu.start"
! _zr_owns_qemu_pid "$pid"

grep -Fq 'refusing to adopt unmanaged qemu pid' "$repo/tools/zbmc"
grep -Fq 'refusing to stop unmanaged qemu pid' "$repo/tools/zbmc"
grep -Fq 'UP (UNMANAGED)' "$repo/tools/zbmc"

echo "QEMU process ownership: PASS"
