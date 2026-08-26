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
  bash -c "sleep 30 & wait" & parent=$!
  while ! child=$(pgrep -P "$parent"); do sleep .01; done
  _background_pids=("$parent")
  _stop_background
  ! kill -0 "$parent" 2>/dev/null && ! kill -0 "$child" 2>/dev/null
' || { echo "status background cleanup failed" >&2; exit 1; }
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
ZBMC_L2_REQUIRED="${TEST_L2_REQUIRED:-1}"
ZBMC_DISABLED_SERVICES="${TEST_DISABLED:-redfish console}"
zbmc_ready(){ echo "ready (fixture)"; }
zbmc_running(){ [ "${TEST_DISCOVER_RUNNING:-0}" = 1 ] && echo "$$"; }
zbmc_ssh(){
  [ "${TEST_SSH_DOWN:-0}" = 1 ] && { echo "no response"; return 1; }
  echo up
}
zbmc_ipmi_health(){
  [ -f "$TEST_ROOT/ipmi-down" ] && { echo "no response"; return 1; }
  mkdir "$TEST_ACTIVITY_ROOT" 2>/dev/null || { echo "concurrent probe"; return 1; }
  sleep .1; rmdir "$TEST_ACTIVITY_ROOT"
  [ "${TEST_FLEET_ORDER:-0}" != 1 ] || : > "$TEST_ROOT/fleet-fake-done"
  echo "fixture IPMI"
}
zbmc_redfish_health(){ [ -z "${TEST_REDFISH_MARK:-}" ] || : > "$TEST_REDFISH_MARK"; echo "no HTTPS response"; return 1; }
zbmc_webui_health(){
  [ -f "$TEST_ROOT/webui-down" ] && { echo "no HTTPS root response"; return 1; }
  echo "fixture Web-UI"
}
zbmc_web(){ printf 'web args: %s\n' "$*"; }
if [ "${TEST_NCSI:-0}" = 1 ]; then
  zbmc_ncsi_health(){ echo "fixture NC-SI"; }
fi
EOF

printf 'run-1\n' > "$TEST_ROOT/current-run"
ln -s run-1 "$TEST_ROOT/runs/latest"
printf '%s\n' "$(( $(date +%s) - 1200 ))" > "$TEST_ROOT/runs/run-1/start-epoch"
cat > "$TEST_ROOT/runs/run-1/result.json" <<'EOF'
{"state":"ready","elapsed_seconds":612,"highest_stage":"READY","cause":""}
EOF
cat > "$TEST_ROOT/runs/run-1/termination.json" <<'EOF'
{"state":"stopped","elapsed_seconds":1200,"highest_stage":"READY","cause":"operator requested shutdown"}
EOF

labels(){ sed -n 's/^\([^:]*\) *:.*/\1/p' | sed 's/[[:space:]]*$//'; }
expect(){ grep -Fq "$2" <<<"$1" || { printf 'missing: %s\n%s\n' "$2" "$1" >&2; exit 1; }; }

ps_fallback=$(TEST_ZBMC="$fixture/tools/zbmc" bash -c '
  eval "$(sed -n '\''/^running(){/,/^  return 1; }/p'\'' "$TEST_ZBMC")"
  PIDF=/nonexistent; ZBMC_IP=192.0.2.10; IPMI_PORT=623
  pgrep(){ return 1; }
  ps(){ [ "$1" = -p ] && return 1; [ "$1" = -ww ] || return 1; printf "4242 qemu-system-arm hostfwd=udp:192.0.2.10:623-10.0.2.15:623\\n"; }
  running
')
[ "$ps_fallback" = 4242 ] || { echo "root-process ps fallback failed: $ps_fallback" >&2; exit 1; }

help=$("$fixture/tools/zbmc")
expect "$help" "NAME                 RESERVED IP     DESCRIPTION"
expect "$help" "fake                 127.0.0.1"
listed=$("$fixture/tools/zbmc" list)
expect "$listed" "fake                 127.0.0.1"

down=$("$fixture/tools/zbmc" fake status)
[ "$(labels <<<"$down")" = $'QEMU\nLast run\nBuild' ] || { printf 'unexpected down status:\n%s\n' "$down" >&2; exit 1; }
expect "$down" "Last run  : READY after 10m 12s; UP for 9m 48s; STOPPED — operator requested shutdown"
[[ "$down" != *"had reached READY"* ]] || { printf 'redundant highest stage:\n%s\n' "$down" >&2; exit 1; }

cat > "$TEST_ROOT/runs/run-1/termination.json" <<'EOF'
{"state":"crashed","elapsed_seconds":43860,"highest_stage":"READY","cause":"QEMU exited unexpectedly"}
EOF
cat > "$TEST_ROOT/runs/run-1/result.json" <<'EOF'
{"state":"ready","elapsed_seconds":209,"highest_stage":"READY","cause":""}
EOF
crashed=$("$fixture/tools/zbmc" fake status)
expect "$crashed" "Last run  : READY after 3m 29s; UP for 12h 7m; CRASHED — QEMU exited unexpectedly"

cat > "$TEST_ROOT/runs/run-1/result.json" <<'EOF'
{"state":"ready","elapsed_seconds":1200,"highest_stage":"READY","cause":""}
EOF
cat > "$TEST_ROOT/runs/run-1/termination.json" <<'EOF'
{"state":"crashed","elapsed_seconds":600,"highest_stage":"READY","cause":"inconsistent history"}
EOF
inconsistent=$("$fixture/tools/zbmc" fake status)
expect "$inconsistent" "Last run  : READY after 20m 0s; CRASHED after 10m 0s — inconsistent history"

cat > "$TEST_ROOT/runs/run-1/result.json" <<'EOF'
{"state":"ready","highest_stage":"READY","cause":""}
EOF
cat > "$TEST_ROOT/runs/run-1/termination.json" <<'EOF'
{"state":"stopped","elapsed_seconds":1200,"highest_stage":"READY","cause":"missing startup duration"}
EOF
missing_duration=$("$fixture/tools/zbmc" fake status)
expect "$missing_duration" "Last run  : READY; STOPPED after 20m 0s — missing startup duration"

cat > "$TEST_ROOT/runs/run-1/result.json" <<'EOF'
{"state":"timeout","elapsed_seconds":900,"highest_stage":"SERVICES","cause":"readiness deadline reached"}
EOF
cat > "$TEST_ROOT/runs/run-1/termination.json" <<'EOF'
{"state":"stopped","elapsed_seconds":1200,"highest_stage":"SERVICES","cause":"operator requested shutdown"}
EOF
never_ready=$("$fixture/tools/zbmc" fake status)
expect "$never_ready" "Last run  : TIMED OUT after 15m 0s (reached SERVICES); STOPPED after 20m 0s — operator requested shutdown"

rm "$TEST_ROOT/runs/run-1/termination.json"
incomplete=$("$fixture/tools/zbmc" fake status)
expect "$incomplete" "Last run  : TIMED OUT after 15m 0s (reached SERVICES); END UNKNOWN"

rm "$TEST_ROOT/runs/run-1/result.json"
cat > "$TEST_ROOT/runs/run-1/termination.json" <<'EOF'
{"state":"crashed","highest_stage":"SERVICES","cause":"QEMU exited unexpectedly"}
EOF
legacy=$("$fixture/tools/zbmc" fake status)
expect "$legacy" "Last run  : CRASHED (reached SERVICES) — QEMU exited unexpectedly"

cat > "$TEST_ROOT/runs/run-1/result.json" <<'EOF'
{"state":"ready","elapsed_seconds":612,"highest_stage":"READY","cause":""}
EOF
cat > "$TEST_ROOT/runs/run-1/termination.json" <<'EOF'
{"state":"stopped","elapsed_seconds":1200,"highest_stage":"READY","cause":"operator requested shutdown"}
EOF

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
expect "$ready" "Health    : READY [4/4 - ICMP, SSH, IPMI, Web-UI]"
expect "$("$fixture/tools/zbmc" fake web --ui-only)" "web args: --ui-only"

cat > "$TEST_ROOT/runs/run-1/result.json" <<'EOF'
{"state":"timeout","elapsed_seconds":900,"highest_stage":"L2","cause":"readiness deadline reached"}
EOF
late_ready=$("$fixture/tools/zbmc" fake status)
expect "$late_ready" "Startup watch : TIMED OUT after 15m 0s (reached ICMP; QEMU still running)"
expect "$late_ready" "Health    : READY [4/4 - ICMP, SSH, IPMI, Web-UI]"
cat > "$TEST_ROOT/runs/run-1/result.json" <<'EOF'
{"state":"ready","elapsed_seconds":612,"highest_stage":"READY","cause":""}
EOF

rm -f "$TEST_ROOT/redfish-probed"
disabled_redfish=$(TEST_REDFISH_MARK="$TEST_ROOT/redfish-probed" "$fixture/tools/zbmc" fake status --verbose)
[ ! -e "$TEST_ROOT/redfish-probed" ] || { echo "disabled Redfish was still probed" >&2; exit 1; }
expect "$disabled_redfish" "Redfish   : N/A (disabled)"
not_configured_redfish=$(TEST_DISABLED=console TEST_REDFISH_MARK="$TEST_ROOT/redfish-probed" "$fixture/tools/zbmc" fake status --verbose)
[ ! -e "$TEST_ROOT/redfish-probed" ] || { echo "unconfigured Redfish was still probed" >&2; exit 1; }
expect "$not_configured_redfish" "Redfish   : N/A (not configured)"

rm "$TEST_ROOT/runs/run-1/result.json"
printf '%s\n' "$(date +%s)" > "$TEST_ROOT/runs/run-1/start-epoch"
printf '%s\n' '{"stage":"BOOTSTRAP","state":"ready"}' > "$TEST_ROOT/runs/run-1/events.jsonl"
touch "$TEST_ROOT/ipmi-down"
unobserved=$("$fixture/tools/zbmc" fake status)
expect "$unobserved" "Startup watch : NOT ACTIVE (last recorded BOOTSTRAP; no terminal result)"
expect "$unobserved" "Health    : DEGRADED [3/4 - ICMP, SSH, Web-UI; IPMI failed]"
printf '%s\n' "$$" > "$TEST_ROOT/runs/run-1/watcher.pid"
starting=$("$fixture/tools/zbmc" fake status)
expect "$starting" "Current run : STARTING ("
expect "$starting" "reached BOOTSTRAP)"
expect "$starting" "Health    : 3/4 READY [ICMP, SSH, Web-UI]; 1 STARTING [IPMI]"

verbose=$("$fixture/tools/zbmc" fake status --verbose)
expect "$verbose" "Observed  :"
expect "$verbose" $'Evidence  : '"$TEST_ROOT/runs/run-1"$'\nConsole log : '"$TEST_ROOT/runs/run-1/console.log (live)"$'\nFollow      : tail -f '"$TEST_ROOT/runs/run-1/console.log"
expect "$verbose" "ICMP      : READY (127.0.0.1 answers ICMP)"
expect "$verbose" "SSH       : READY (zbmc 127.0.0.1 ssh)"
expect "$verbose" "IPMI      : STARTING"
[[ "$(grep '^IPMI' <<<"$verbose")" != *"("* ]] || { printf 'starting row included probe failure detail:\n%s\n' "$verbose" >&2; exit 1; }
expect "$verbose" "Redfish   : N/A (disabled)"
expect "$verbose" "Web-UI    : READY (fixture Web-UI"
expect "$verbose" "Console   : N/A (disabled)"

# A root-started run can leave current-run unreadable to the ordinary operator;
# status must still discover the group-readable runs/latest evidence link.
chmod 000 "$TEST_ROOT/current-run"
unprivileged=$("$fixture/tools/zbmc" fake status --verbose)
expect "$unprivileged" "Evidence  : $TEST_ROOT/runs/run-1"
chmod 600 "$TEST_ROOT/current-run"
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
expect "$ncsi" "Health    : 4/5 READY [ICMP, SSH, Web-UI, NC-SI]; 1 STARTING [IPMI]"

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
expect "$no_web" "Health    : DEGRADED [3/4 - ICMP, SSH, IPMI; Redfish failed]"

printf 'fake 192.0.2.1\n' > "$fixture/zhosts.txt"
touch "$TEST_ROOT/ipmi-down" "$TEST_ROOT/webui-down"
printf '%s\n' '{"command":"zbmc fake start"}' > "$TEST_ROOT/runs/run-1/manifest.json"
all_failed=$(TEST_SSH_DOWN=1 "$fixture/tools/zbmc" fake status)
expect "$all_failed" "Health    : DEGRADED [0/4 - ICMP, SSH, IPMI, Web-UI failed]"
[[ "$all_failed" != *" - ;"* ]] || { printf 'malformed health detail:\n%s\n' "$all_failed" >&2; exit 1; }
printf 'fake 127.0.0.1\n' > "$fixture/zhosts.txt"
rm -f "$TEST_ROOT/ipmi-down" "$TEST_ROOT/webui-down"
printf '%s\n' '{"command":"zbmc fake start --no-web"}' > "$TEST_ROOT/runs/run-1/manifest.json"
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

printf '%s\n' '{"command":"zbmc fake start --no-web"}' > "$TEST_ROOT/runs/run-1/manifest.json"
console_required=$(TEST_REQUIRED=console TEST_L2_REQUIRED=0 TEST_DISABLED=redfish "$fixture/tools/zbmc" fake status)
expect "$console_required" "Health    : READY [1/1 - Console]"
console_required_v=$(TEST_REQUIRED=console TEST_L2_REQUIRED=0 TEST_DISABLED=redfish "$fixture/tools/zbmc" fake status -v)
expect "$console_required_v" "ICMP      : N/A (not configured)"

runlib_probe=$(TEST_ROOT="$TEST_ROOT" bash -c '
  ZBMC_SOURCE_ONLY=1 . "'"$fixture"'/tools/zbmc"
  ZBMC_NAME=fake; ZBMC_IP=127.0.0.1; WEB_PORT=443
  zbmc_webui_health(){ echo "runlib Web-UI"; }
  . "'"$fixture"'/tools/zbmc-runlib"
  _zr_probe_service webui "$TEST_ROOT/runlib-webui"
  cat "$TEST_ROOT/runlib-webui"
')
expect "$runlib_probe" "ok|curl -sk https://127.0.0.1:443/|runlib Web-UI"
rm -f "$TEST_ROOT/webui-down" "$TEST_ROOT/runs/run-1/manifest.json" "$TEST_ROOT/runlib-webui"

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
zbmc_ready(){
  if [ "${TEST_FLEET_ORDER:-0}" = 1 ] && [ ! -e "$TEST_ROOT/fleet-fake-done" ]; then
    : > "$TEST_ROOT/fleet-overlap"
  fi
  sleep 2; : > "$TEST_ROOT/slow-build-done"; echo "ready (slow fixture)"
}
EOF
TEST_FLEET_ORDER=1 "$fixture/tools/zbmc" all > "$fixture/all-output" & all_pid=$!
for _ in $(seq 1 30); do grep -q '===== slow (2/2) =====' "$fixture/all-output" && break; sleep .1; done
expect "$(cat "$fixture/all-output")" "===== slow (2/2) ====="
[ ! -e "$TEST_ROOT/slow-build-done" ] || { echo "slow header printed after its status completed" >&2; exit 1; }
wait "$all_pid"
[ ! -e "$TEST_ROOT/fleet-overlap" ] || { echo "fleet status probes overlapped" >&2; exit 1; }

rm -f "$TEST_ROOT/fleet-fake-done" "$TEST_ROOT/fleet-overlap"
TEST_FLEET_ORDER=1 "$fixture/tools/zbmc" all -f > "$fixture/all-fast-output"
[ -e "$TEST_ROOT/fleet-overlap" ] || { echo "fast fleet status did not run in parallel" >&2; exit 1; }

fleet_verbose=$("$fixture/tools/zbmc" all status -v)
expect "$fleet_verbose" "Observed  :"
fleet_shorthand=$("$fixture/tools/zbmc" all -v)
expect "$fleet_shorthand" "checking status on 2 inmates"
expect "$fleet_shorthand" "Observed  :"

echo "status output: PASS"
