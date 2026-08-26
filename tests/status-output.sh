#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
export TEST_ROOT="$fixture/work/fake"
export TEST_ACTIVITY_ROOT="$fixture/ipmi-active"

mkdir -p "$fixture/tools" "$fixture/boxes/fake" "$TEST_ROOT/runs/run-1"
cp "$repo/tools/zbmc" "$repo/tools/zbmc-runlib" "$fixture/tools/"
TEST_ZBMC="$fixture/tools/zbmc" bash -c '
  ZBMC_SOURCE_ONLY=1 . "$TEST_ZBMC"
  sleep 30 & _spinner_pid=$!; spinner=$_spinner_pid
  _stop_spinner
  ! kill -0 "$spinner" 2>/dev/null
' || { echo "spinner cleanup failed" >&2; exit 1; }
printf 'fake 127.0.0.1\n' > "$fixture/zhosts.txt"
cat > "$fixture/boxes/fake/zbmc.box" <<'EOF'
ZBMC_NAME=fake
ZBMC_DESC="status fixture"
ZBMC_DIR="$TEST_ROOT"
ZBMC_IP=$(_zbmc_resolve_ip fake 2 127.0.0.1)
ZBMC_HOST=fake
ZBMC_SSH_NOTE="${TEST_SSH_NOTE:-}"
PIDF="$ZBMC_DIR/zbmc.pid"
LOG="$ZBMC_DIR/console.log"
CONSOLE_LOG="$LOG"
IPMI_USER=root
IPMI_PW=test
ZBMC_REQUIRED_SERVICES="${TEST_REQUIRED:-ssh ipmi}"
ZBMC_DISABLED_SERVICES="${TEST_DISABLED:-redfish console}"
zbmc_ready(){ echo "ready (fixture)"; }
zbmc_running(){ [ "${TEST_DISCOVER_RUNNING:-0}" = 1 ] && echo "$$"; }
zbmc_ssh(){ echo up; }
zbmc_ipmi_health(){
  [ -f "$TEST_ROOT/ipmi-down" ] && { echo "no response"; return 1; }
  mkdir "$TEST_ACTIVITY_ROOT" 2>/dev/null || { echo "concurrent probe"; return 1; }
  sleep .1; rmdir "$TEST_ACTIVITY_ROOT"; echo "fixture IPMI"
}
zbmc_redfish_health(){ echo "no HTTPS response"; return 1; }
zbmc_webui_health(){
  [ -f "$TEST_ROOT/webui-down" ] && { echo "no HTTPS root response"; return 1; }
  echo "fixture Web-UI"
}
if [ "${TEST_NCSI:-0}" = 1 ]; then
  zbmc_ncsi_health(){ echo "fixture NC-SI"; }
fi
EOF

printf 'run-1\n' > "$TEST_ROOT/current-run"
printf '%s\n' "$(( $(date +%s) - 1200 ))" > "$TEST_ROOT/runs/run-1/start-epoch"
cat > "$TEST_ROOT/runs/run-1/result.json" <<'EOF'
{"state":"ready","elapsed_seconds":612,"highest_stage":"READY","cause":""}
EOF
cat > "$TEST_ROOT/runs/run-1/termination.json" <<'EOF'
{"state":"stopped","elapsed_seconds":1200,"highest_stage":"READY","cause":"operator requested shutdown"}
EOF

labels(){ sed -n 's/^\([^:]*\) *:.*/\1/p' | sed 's/[[:space:]]*$//'; }
expect(){ grep -Fq "$2" <<<"$1" || { printf 'missing: %s\n%s\n' "$2" "$1" >&2; exit 1; }; }

down=$("$fixture/tools/zbmc" fake status)
[ "$(labels <<<"$down")" = $'QEMU\nLast run\nBuild' ] || { printf 'unexpected down status:\n%s\n' "$down" >&2; exit 1; }
expect "$down" "Last run  : STOPPED"
expect "$down" "had reached READY"

down_verbose=$("$fixture/tools/zbmc" fake status --verbose)
expect "$down_verbose" "Evidence  : $TEST_ROOT/runs/run-1"
expect "$down_verbose" "Console log : N/A"

rm "$TEST_ROOT/runs/run-1/termination.json"
printf '%s\n' "$$" > "$TEST_ROOT/zbmc.pid"
printf 'current run serial output\n' > "$TEST_ROOT/runs/run-1/console.log"
ready=$("$fixture/tools/zbmc" fake status)
[ "$(labels <<<"$ready")" = $'QEMU\nCurrent run\nBuild\nHealth' ] || { printf 'unexpected ready status:\n%s\n' "$ready" >&2; exit 1; }
[[ "$ready" != *"checking services"* ]] || { printf 'spinner leaked into captured output:\n%s\n' "$ready" >&2; exit 1; }
expect "$ready" "Current run : READY (startup took 10m 12s)"
expect "$ready" "Health    : READY [4/4 - L2, SSH, IPMI, Web-UI]"

rm "$TEST_ROOT/runs/run-1/result.json"
printf '%s\n' "$(date +%s)" > "$TEST_ROOT/runs/run-1/start-epoch"
printf '%s\n' '{"stage":"BOOTSTRAP","state":"ready"}' > "$TEST_ROOT/runs/run-1/events.jsonl"
touch "$TEST_ROOT/ipmi-down"
starting=$("$fixture/tools/zbmc" fake status)
expect "$starting" "Current run : STARTING ("
expect "$starting" "reached BOOTSTRAP)"
expect "$starting" "Health    : STARTING"
expect "$starting" "STARTING [3/4 - L2, SSH, Web-UI; IPMI coming online]"

verbose=$("$fixture/tools/zbmc" fake status --verbose)
expect "$verbose" "Observed  :"
expect "$verbose" $'Evidence  : '"$TEST_ROOT/runs/run-1"$'\nConsole log : '"$TEST_ROOT/runs/run-1/console.log (live)"$'\nFollow      : tail -f '"$TEST_ROOT/runs/run-1/console.log"
expect "$verbose" "L2        : READY (127.0.0.1 answers ICMP)"
expect "$verbose" "SSH       : READY (zbmc 127.0.0.1 ssh)"
expect "$verbose" "IPMI      : STARTING (expected; no response)"
expect "$verbose" "Redfish   : N/A (disabled)"
expect "$verbose" "Web-UI    : READY (fixture Web-UI"
expect "$verbose" "Console   : N/A (disabled)"
[[ "$verbose" != *"NC-SI"* ]] || { printf 'unexpected NC-SI row:\n%s\n' "$verbose" >&2; exit 1; }

ssh_note=$(TEST_SSH_NOTE='prompt is "/admin1->", but is a real shell' "$fixture/tools/zbmc" fake status --verbose)
expect "$ssh_note" 'SSH       : READY (zbmc 127.0.0.1 ssh; prompt is "/admin1->", but is a real shell)'

mv "$TEST_ROOT/runs/run-1/console.log" "$TEST_ROOT/runs/run-1/console.saved"
printf 'legacy live serial output\n' > "$TEST_ROOT/console.log"
legacy_verbose=$("$fixture/tools/zbmc" fake status --verbose)
expect "$legacy_verbose" "Console log : $TEST_ROOT/console.log (live)"
expect "$legacy_verbose" "Follow      : tail -f $TEST_ROOT/console.log"
mv "$TEST_ROOT/runs/run-1/console.saved" "$TEST_ROOT/runs/run-1/console.log"

rm "$TEST_ROOT/zbmc.pid"
archived=$("$fixture/tools/zbmc" fake status --verbose)
expect "$archived" "Console log : $TEST_ROOT/runs/run-1/console.log (archived)"
[[ "$archived" != *"Follow      :"* ]] || { printf 'unexpected archived follow command:\n%s\n' "$archived" >&2; exit 1; }
printf '%s\n' "$$" > "$TEST_ROOT/zbmc.pid"

printf 'stale descriptor log\n' > "$TEST_ROOT/console.log"
console_output=$(timeout 1 "$fixture/tools/zbmc" fake console 2>&1 || :)
expect "$console_output" "current run serial output"
[[ "$console_output" != *"stale descriptor log"* ]] || { printf 'console tailed stale descriptor log:\n%s\n' "$console_output" >&2; exit 1; }

ncsi=$(TEST_NCSI=1 "$fixture/tools/zbmc" fake status --verbose)
expect "$ncsi" "NC-SI     : READY (fixture NC-SI)"
expect "$ncsi" "Health    : STARTING [4/5 - L2, SSH, Web-UI, NC-SI; IPMI coming online]"

runlib_ncsi=$(TEST_ROOT="$TEST_ROOT" bash -c '
  ZBMC_SOURCE_ONLY=1 . "'"$fixture"'/tools/zbmc"
  ZBMC_NAME=fake; ZBMC_IP=127.0.0.1; ZBMC_DESCRIPTOR_REQUIRED_SERVICES="ssh ipmi"
  zbmc_ncsi_health(){ echo "fixture NC-SI"; }
  . "'"$fixture"'/tools/zbmc-runlib"
  _zr_set_effective_services 0
  _zr_probe_service ncsi "$TEST_ROOT/runlib-ncsi"
  printf "%s|" "$ZBMC_REQUIRED_SERVICES"
  cat "$TEST_ROOT/runlib-ncsi"
')
expect "$runlib_ncsi" "ssh ipmi webui ncsi|ok||fixture NC-SI"
rm "$TEST_ROOT/runlib-ncsi"

shorthand=$("$fixture/tools/zbmc" fake -v)
expect "$shorthand" "Observed  :"

rm "$TEST_ROOT/ipmi-down"
cat > "$TEST_ROOT/runs/run-1/result.json" <<'EOF'
{"state":"ready","elapsed_seconds":612,"highest_stage":"READY","cause":""}
EOF
expected_failure=$(TEST_DISABLED=console TEST_REQUIRED="ssh ipmi redfish" "$fixture/tools/zbmc" fake status)
expect "$expected_failure" "Health    : DEGRADED"
expect "$expected_failure" "Redfish failed]"

touch "$TEST_ROOT/webui-down"
cat > "$TEST_ROOT/runs/run-1/manifest.json" <<'EOF'
{"command":"zbmc fake start --no-web"}
EOF
no_web=$(TEST_DISABLED=console TEST_REQUIRED="ssh ipmi redfish" "$fixture/tools/zbmc" fake status --verbose)
expect "$no_web" "Redfish   : FAILED (expected; no HTTPS response)"
expect "$no_web" "Web-UI    : N/A (disabled)"
expect "$no_web" "Health    : DEGRADED [3/4 - L2, SSH, IPMI; Redfish failed]"
runlib_no_web=$(TEST_ROOT="$TEST_ROOT" bash -c '
  ZBMC_DIR="$TEST_ROOT"; ZBMC_DESCRIPTOR_REQUIRED_SERVICES="ssh ipmi redfish"
  . "'"$fixture"'/tools/zbmc-runlib"
  _zr_load ""
  printf "%s|%s\n" "$ZBMC_REQUIRED_SERVICES" "$ZBMC_WEBUI_DISABLED"
')
[ "$runlib_no_web" = "ssh ipmi redfish|1" ] || { echo "unexpected --no-web runlib services: $runlib_no_web" >&2; exit 1; }

cat > "$TEST_ROOT/runs/run-1/manifest.json" <<'EOF'
{"command":"zbmc fake start"}
EOF
runlib_default=$(TEST_ROOT="$TEST_ROOT" bash -c '
  ZBMC_DIR="$TEST_ROOT"; ZBMC_DESCRIPTOR_REQUIRED_SERVICES="ssh ipmi redfish"
  . "'"$fixture"'/tools/zbmc-runlib"
  _zr_load ""
  printf "%s|%s\n" "$ZBMC_REQUIRED_SERVICES" "$ZBMC_WEBUI_DISABLED"
')
[ "$runlib_default" = "ssh ipmi redfish webui|0" ] || { echo "unexpected default runlib services: $runlib_default" >&2; exit 1; }

runlib_probe=$(TEST_ROOT="$TEST_ROOT" bash -c '
  ZBMC_SOURCE_ONLY=1 . "'"$fixture"'/tools/zbmc"
  ZBMC_NAME=fake; ZBMC_IP=127.0.0.1; WEB_PORT=443
  zbmc_webui_health(){ echo "runlib Web-UI"; }
  . "'"$fixture"'/tools/zbmc-runlib"
  _zr_probe_service webui "$TEST_ROOT/runlib-webui"
  cat "$TEST_ROOT/runlib-webui"
')
expect "$runlib_probe" "ok|curl -sk https://127.0.0.1:443/|runlib Web-UI"
rm "$TEST_ROOT/webui-down" "$TEST_ROOT/runs/run-1/manifest.json" "$TEST_ROOT/runlib-webui"

runlib_console=$(TEST_ROOT="$TEST_ROOT" bash -c '
  set -e
  ZBMC_DIR="$TEST_ROOT/init-contract"; ZBMC_NAME=fake; ZBMC_IP=127.0.0.1
  LOG=; CONSOLE_LOG="$TEST_ROOT/legacy-console.log"
  mkdir -p "$ZBMC_DIR"
  . "'"$fixture"'/tools/zbmc-runlib"
  _zr_manifest(){ :; }; _zr_snapshot(){ :; }; _zr_event(){ :; }
  _zr_init boot
  printf "serial evidence\n" > "$ZBMC_CONSOLE_LOG"
  _zr_archive_logs
  printf "%s|%s|%s|" "$ZBMC_CONSOLE_LOG" "$CONSOLE_LOG" "$(bash -c '\''printf %s "$ZBMC_CONSOLE_LOG"'\'')"
  cat "$ZBMC_CONSOLE_LOG"
')
IFS='|' read -r run_console descriptor_console child_console run_console_text <<<"$runlib_console"
[ "$run_console" = "$descriptor_console" ] || { echo "CONSOLE_LOG was not rebound: $runlib_console" >&2; exit 1; }
[ "$run_console" = "$child_console" ] || { echo "ZBMC_CONSOLE_LOG was not exported: $runlib_console" >&2; exit 1; }
[[ "$run_console" == "$TEST_ROOT/init-contract/runs/"*/console.log ]] || { echo "unexpected run console path: $run_console" >&2; exit 1; }
[ "$run_console_text" = "serial evidence" ] || { echo "self-archive changed console evidence: $runlib_console" >&2; exit 1; }

follow=$("$fixture/tools/zbmc" fake status --follow)
expect "$follow" "Current run : READY (startup took 10m 12s)"

rm "$TEST_ROOT/runs/run-1/result.json"
: > "$TEST_ROOT/runs/run-1/progress.log"
( sleep 1; echo '[00:01] IPMI ready' >> "$TEST_ROOT/runs/run-1/progress.log" ) & watcher=$!
printf '%s\n' "$watcher" > "$TEST_ROOT/runs/run-1/watcher.pid"
active_follow=$("$fixture/tools/zbmc" fake status --follow)
expect "$active_follow" "Progress (Ctrl-C stops following; QEMU keeps running):"
expect "$active_follow" "[00:01] IPMI ready"
cat > "$TEST_ROOT/runs/run-1/result.json" <<'EOF'
{"state":"ready","elapsed_seconds":612,"highest_stage":"READY","cause":""}
EOF

if command -v flock >/dev/null 2>&1; then
  "$fixture/tools/zbmc" fake status > "$fixture/status-a" & a=$!
  "$fixture/tools/zbmc" fake status > "$fixture/status-b" & b=$!
  wait "$a"; wait "$b"
  expect "$(cat "$fixture/status-a")" "Health    : READY"
  expect "$(cat "$fixture/status-b")" "Health    : READY"

  rm -f "$TEST_ROOT/zbmc.pid"
  rm -rf "$TEST_ROOT/tmp"
  chmod a-w "$TEST_ROOT"
  readonly_work=$(TEST_DISCOVER_RUNNING=1 "$fixture/tools/zbmc" fake status 2>&1)
  chmod u+w "$TEST_ROOT"
  expect "$readonly_work" "QEMU      : UP"
  expect "$readonly_work" "Health    : READY"
  [ ! -e "$TEST_ROOT/zbmc.pid" ] || { echo "status wrote discovered PID into ZBMC_DIR" >&2; exit 1; }
  [[ "$readonly_work" != *"Permission denied"* ]] || { printf '%s\n' "$readonly_work" >&2; exit 1; }
fi

mkdir -p "$fixture/boxes/slow" "$fixture/work/slow"
printf 'slow 127.0.0.1\n' >> "$fixture/zhosts.txt"
cat > "$fixture/boxes/slow/zbmc.box" <<'EOF'
ZBMC_NAME=slow
ZBMC_DESC="delayed status fixture"
ZBMC_DIR="$TEST_ROOT/../slow"
ZBMC_IP=$(_zbmc_resolve_ip slow 3 127.0.0.1)
ZBMC_HOST=slow
PIDF="$ZBMC_DIR/zbmc.pid"
LOG="$ZBMC_DIR/console.log"
zbmc_ready(){ sleep 2; : > "$TEST_ROOT/slow-build-done"; echo "ready (slow fixture)"; }
EOF
"$fixture/tools/zbmc" all > "$fixture/all-output" & all_pid=$!
for _ in $(seq 1 30); do grep -q '===== slow (2/2) =====' "$fixture/all-output" && break; sleep .1; done
expect "$(cat "$fixture/all-output")" "===== slow (2/2) ====="
[ ! -e "$TEST_ROOT/slow-build-done" ] || { echo "slow header printed after its status completed" >&2; exit 1; }
wait "$all_pid"

echo "status output: PASS"
