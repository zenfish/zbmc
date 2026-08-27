#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

qemu="$fixture/qemu-system-arm"
printf '#!/usr/bin/env bash\nexit 0\n' >"$qemu"
chmod +x "$qemu"
sha="$(sha256sum "$qemu" | awk '{print $1}')"
python3 - "$fixture/manifest.json" "$qemu" "$sha" <<'PY'
import json
import sys

path, binary, sha256 = sys.argv[1:]
json.dump({
    "build_id": "fixture-build",
    "binary": binary,
    "binary_sha256": sha256,
    "boxes": ["one", "two"],
}, open(path, "w"))
PY

fake_zbmc="$fixture/zbmc"
cat >"$fake_zbmc" <<'EOF'
#!/usr/bin/env bash
set -eu
printf '%s\n' "$*" >>"$CALLS"
box=$1 verb=$2
case "$verb" in
  status)
    if [ -f "$STATE.$box" ]; then
      printf 'QEMU      : UP\nEvidence  : %s/%s\nBuild     : READY\nHealth    : READY [1/1 - fixture]\n' "$RUN" "$box"
    else
      printf 'QEMU      : DOWN\nBuild     : READY\n'
    fi
    ;;
  start)
    mkdir -p "$RUN/$box"
    python3 - "$RUN/$box/manifest.json" "$BINARY" "$BINARY_SHA" <<'PY'
import json, sys
path, binary, sha = sys.argv[1:]
json.dump({"qemu_path": binary, "qemu_sha256": sha}, open(path, "w"))
PY
    : >"$STATE.$box"
    printf 'Evidence: %s/%s\n' "$RUN" "$box"
    ;;
  stop) rm -f "$STATE.$box" ;;
esac
EOF
chmod +x "$fake_zbmc"

CALLS="$fixture/calls" STATE="$fixture/state" RUN="$fixture/runs" BINARY="$qemu" BINARY_SHA="$sha" \
  ZBMC_TOOL="$fake_zbmc" ZBMC_VALIDATE_RUN_AS_ME=1 \
  QEMU_VALIDATION_ROOT="$fixture/evidence" \
  "$repo/tools/validate-qemu-build" --deadline 9 "$fixture/manifest.json" >/dev/null

grep -Fx "one start --deadline 9 -q $qemu" "$fixture/calls" >/dev/null
grep -Fx 'one status' "$fixture/calls" >/dev/null
grep -Fx 'one status -v' "$fixture/calls" >/dev/null
grep -Fx 'one stop' "$fixture/calls" >/dev/null
grep -Fx "two start --deadline 9 -q $qemu" "$fixture/calls" >/dev/null
summary="$(find "$fixture/evidence" -name summary.tsv -type f)"
[ "$(wc -l <"$summary" | tr -d ' ')" = 2 ]
grep -Fq $'one\tstart=0\tstatus=0\tmanifest=0\tstop=0\tPASS' "$summary"
grep -Fq $'two\tstart=0\tstatus=0\tmanifest=0\tstop=0\tPASS' "$summary"

: >"$fixture/state.one"
if CALLS="$fixture/running-calls" STATE="$fixture/state" RUN="$fixture/runs" BINARY="$qemu" BINARY_SHA="$sha" \
    ZBMC_TOOL="$fake_zbmc" ZBMC_VALIDATE_RUN_AS_ME=1 QEMU_VALIDATION_ROOT="$fixture/running-evidence" \
    "$repo/tools/validate-qemu-build" "$fixture/manifest.json" one >/dev/null 2>&1; then
  echo 'validator accepted an already running box' >&2
  exit 1
fi
grep -Fx 'one status' "$fixture/running-calls"
! grep -q 'one start' "$fixture/running-calls"
! grep -q 'one stop' "$fixture/running-calls"
rm "$fixture/state.one"

hup_zbmc="$fixture/hup-zbmc"
cat >"$hup_zbmc" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$CALLS"
case "$2" in
  start)
    printf '%s\n' "$$" >"$START_PID"
    trap 'exit 0' TERM
    while :; do sleep 1; done
    ;;
  stop)
    kill -TERM "$(cat "$START_PID")" 2>/dev/null || true
    ;;
esac
EOF
chmod +x "$hup_zbmc"

: >"$fixture/hup-calls"
CALLS="$fixture/hup-calls" START_PID="$fixture/start.pid" ZBMC_TOOL="$hup_zbmc" \
  ZBMC_VALIDATE_RUN_AS_ME=1 QEMU_VALIDATION_ROOT="$fixture/hup-evidence" \
  "$repo/tools/validate-qemu-build" "$fixture/manifest.json" one >/dev/null 2>&1 &
validator_pid=$!
for _ in {1..50}; do
  grep -Fq "one start --deadline 1200 -q $qemu" "$fixture/hup-calls" && break
  sleep 0.1
done
grep -Fq "one start --deadline 1200 -q $qemu" "$fixture/hup-calls"
kill -HUP "$validator_pid"
set +e
wait "$validator_pid"
hup_rc=$?
set -e
[ "$hup_rc" -eq 130 ]
grep -Fx 'one stop' "$fixture/hup-calls"

echo 'QEMU build fleet validation: PASS'
