#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
python3 - "$repo/qemu/patches/lenovo-xcc-timer-frequency.patch" <<'PY'
import pathlib
import re
import sys

patch = pathlib.Path(sys.argv[1]).read_text()
old, = re.findall(r'^-.*"cntfrq", (\d+),$', patch, re.M)
new, = re.findall(r'^\+.*"cntfrq", (\d+),$', patch, re.M)

# QEMU 98b060da: gt_cntfrq_period_ns and gt_get_countervalue.
def elapsed_guest_seconds(frequency, host_seconds):
    period_ns = max(1, 1_000_000_000 // frequency)
    return (host_seconds * 1_000_000_000 // period_ns) / frequency

assert elapsed_guest_seconds(int(old), 3600) == 3200
assert elapsed_guest_seconds(int(new), 3600) == 3600
assert elapsed_guest_seconds(int(new), 60) == 60
print('Lenovo architectural timer frequency invariant: PASS')
PY
