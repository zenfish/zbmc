#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
tmp=$(mktemp -d)
replacement_file="$tmp/replacement.pid"
cleanup(){
  [ ! -f "$replacement_file" ] || kill "$(cat "$replacement_file")" 2>/dev/null || true
  [ -z "${controller:-}" ] || kill "$controller" 2>/dev/null || true
  rm -f "$tmp"/probes/* "$tmp"/* 2>/dev/null || true
  rmdir "$tmp"/probes "$tmp" 2>/dev/null || true
}
trap cleanup EXIT

ZBMC_RUN_DIR="$tmp" ZBMC_RUN_ID=test ZBMC_RUN_START_EPOCH=$(date +%s)
ZBMC_IP=127.0.0.1 ZBMC_REQUIRED_SERVICES=console ZBMC_QEMU_RESTART_GRACE=5
ZBMC_CONSOLE_LOG="$tmp/console.log" PIDF="$tmp/qemu.pid" LOG="$tmp/launcher.log"
export ZBMC_RUN_DIR ZBMC_RUN_ID ZBMC_RUN_START_EPOCH ZBMC_IP ZBMC_REQUIRED_SERVICES
export ZBMC_QEMU_RESTART_GRACE ZBMC_CONSOLE_LOG PIDF LOG
: >"$ZBMC_CONSOLE_LOG"
. "$repo/tools/zbmc-runlib"

_zr_event(){ printf '%s|%s|%s\n' "$1" "$2" "$3" >>"$tmp/events"; }
_zr_timing(){ :; }; _zr_archive_logs(){ :; }; _zr_qmp_snapshot(){ :; }
_zr_snapshot(){ :; }; _zr_capture_stop(){ :; }; _zr_health_watch(){ :; }
_zr_expected(){ printf 'time unknown'; }
_zr_result(){ printf '%s|%s\n' "$1" "$2" >"$tmp/result"; }
_zr_service_disabled(){ return 1; }
_zr_service_should_probe(){ [ "$1" = console ]; }
_probe_console(){
  [ -f "$replacement_file" ] && [ "$(cat "$PIDF" 2>/dev/null)" = "$(cat "$replacement_file")" ] \
    && echo 'ok|replacement console|ready' || echo 'fail||waiting'
}
running(){
  [ -f "$replacement_file" ] || return 1
  local p; p=$(cat "$replacement_file")
  ps -p "$p" >/dev/null 2>&1 || return 1
  echo "$p"
}

sleep 0.2 & initial=$!
printf '%s\n' "$initial" >"$PIDF"
( sleep 1; sleep 20 & echo $! >"$replacement_file"; wait ) & controller=$!
_zr_wait_ready "$initial" 15 >/dev/null

grep -q '^QEMU|rerolled|launcher replaced pid ' "$tmp/events"
grep -qx 'ready|READY' "$tmp/result"
[ "$(cat "$PIDF")" = "$(cat "$replacement_file")" ]
grep -Fq 'ZBMC_QEMU_RESTART_GRACE=15' "$repo/boxes/megarac-hpe/zbmc.box"
echo "QEMU reroll watcher: PASS"
