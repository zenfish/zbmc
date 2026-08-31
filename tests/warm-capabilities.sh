#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
out=$($repo/tools/zbmc list)

grep -Eq '^NAME +RESERVED IP +WARM$' <<<"$out"
grep -Eq '^idrac10 +[^ ]+ +(READY|MISSING)$' <<<"$out"
grep -Eq '^megarac-hpe +[^ ]+ +(READY|MISSING)$' <<<"$out"
grep -Eq '^supermicro-x14 +[^ ]+ +(READY|MISSING)$' <<<"$out"
grep -Eq '^idrac9 +[^ ]+ +BROKEN$' <<<"$out"
grep -Eq '^openbmc +[^ ]+ +UNAVAILABLE$' <<<"$out"
grep -Fq 'warm-20260831/state.gz' "$repo/boxes/idrac10/build.sh"
grep -Fq '00aaf1b1d150d1fb410b6f5755c2950d5b0fbd07e1fba656e9f468d115256d2d' "$repo/boxes/idrac10/build.sh"

if $repo/tools/zbmc idrac9 start --warm --run-as-me >"${TMPDIR:-/tmp}/zbmc-warm-test.$$" 2>&1; then
  echo 'idrac9 unexpectedly accepted --warm' >&2
  exit 1
fi
grep -Fq 'warm restore is broken: restored usb-net is network-dead' "${TMPDIR:-/tmp}/zbmc-warm-test.$$"
rm -f "${TMPDIR:-/tmp}/zbmc-warm-test.$$"

echo 'warm capabilities: PASS'
