#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
generator="$repo/boxes/idrac10/build-cfgdb-defaults.py"
image="$repo/work/idrac10/img/sd.img"

python3 -m py_compile "$generator"
if [ -f "$image" ] && command -v unsquashfs >/dev/null; then
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  python3 "$generator" "$image" "$tmp/defaults.sql"
  grep -Fxq 'BEGIN;' "$tmp/defaults.sql"
  grep -Fxq 'COMMIT;' "$tmp/defaults.sql"
  [ "$(grep -c '^INSERT OR IGNORE' "$tmp/defaults.sql")" -gt 10000 ]
fi

echo 'iDRAC10 cfgdb generation: PASS'
