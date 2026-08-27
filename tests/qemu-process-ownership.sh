#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

PIDF="$tmp/zbmc.pid"
ZBMC_RUN_DIR="$tmp/run"
mkdir -p "$ZBMC_RUN_DIR"
. "$repo/tools/zbmc-runlib"

! _zr_owns_qemu_pid 123
_zr_record_qemu_pid 123
[ "$(cat "$PIDF")" = 123 ]
_zr_owns_qemu_pid 123
! _zr_owns_qemu_pid 456

grep -Fq 'refusing to adopt unmanaged qemu pid' "$repo/tools/zbmc"
grep -Fq 'refusing to stop unmanaged qemu pid' "$repo/tools/zbmc"
grep -Fq 'UP (UNMANAGED)' "$repo/tools/zbmc"

echo "QEMU process ownership: PASS"
