#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

ZBMC_RUN_DIR="$tmp/run"
ZBMC_RUN_ID=test
ZBMC_RUN_START_EPOCH=$(date +%s)
ZBMC_REQUIRED_SERVICES=ipmi
ZBMC_IP=127.0.0.1
mkdir -p "$ZBMC_RUN_DIR"
. "$repo/tools/zbmc-runlib"

_zr_termination(){ printf '%s\n' "$1" >"$tmp/termination"; }

: >"$ZBMC_RUN_DIR/stop-requested"
_zr_health_watch 999999
[ ! -e "$tmp/termination" ]

rm "$ZBMC_RUN_DIR/stop-requested"
_zr_health_watch 999999
grep -Fxq crashed "$tmp/termination"

echo "clean stop classification: PASS"
