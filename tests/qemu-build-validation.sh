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
# The generated fixture expands these variables.
# shellcheck disable=SC2016
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$*" >>"$CALLS"\nexit 0\n' >"$fake_zbmc"
chmod +x "$fake_zbmc"

CALLS="$fixture/calls" ZBMC_TOOL="$fake_zbmc" ZBMC_VALIDATE_RUN_AS_ME=1 \
  QEMU_VALIDATION_ROOT="$fixture/evidence" \
  "$repo/tools/validate-qemu-build" --deadline 9 "$fixture/manifest.json" >/dev/null

grep -Fx "one start --deadline 9 -q $qemu" "$fixture/calls" >/dev/null
grep -Fx 'one status -v' "$fixture/calls" >/dev/null
grep -Fx 'one stop' "$fixture/calls" >/dev/null
grep -Fx "two start --deadline 9 -q $qemu" "$fixture/calls" >/dev/null
summary="$(find "$fixture/evidence" -name summary.tsv -type f)"
[ "$(wc -l <"$summary" | tr -d ' ')" = 2 ]
grep -Fq $'one\tstart=0\tstatus=0\tstop=0\tPASS' "$summary"
grep -Fq $'two\tstart=0\tstatus=0\tstop=0\tPASS' "$summary"

echo 'QEMU build fleet validation: PASS'
