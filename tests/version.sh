#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
for option in -V --version --Version; do
  [ "$("$repo/tools/zbmc" "$option")" = 'zbmc 0.1.1' ]
done

echo 'zbmc version output: PASS'
