#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
out=$($repo/tools/zbmc list)

grep -Eq '^NAME +RESERVED IP +NETWORK +WARM$' <<<"$out"
grep -Eq '^idrac10 +[^ ]+ +USER/FORWARDED +(READY|MISSING)$' <<<"$out"
grep -Eq '^megarac-hpe +[^ ]+ +USER/FORWARDED +BROKEN$' <<<"$out"
grep -Eq '^supermicro-x14 +[^ ]+ +USER/FORWARDED +(READY|MISSING)$' <<<"$out"
grep -Eq '^idrac9 +[^ ]+ +USER/FORWARDED +BROKEN$' <<<"$out"
grep -Eq '^openbmc +[^ ]+ +USER/FORWARDED +UNAVAILABLE$' <<<"$out"

for box in "$repo"/boxes/*/zbmc.box; do
  grep -Eq '^ZBMC_NETWORK_MODE=(user|tap)$' "$box" || { echo "network mode missing: $box" >&2; exit 1; }
done
grep -Fq 'warm-20260831/state.gz' "$repo/boxes/idrac10/build.sh"
grep -Fq '00aaf1b1d150d1fb410b6f5755c2950d5b0fbd07e1fba656e9f468d115256d2d' "$repo/boxes/idrac10/build.sh"

if $repo/tools/zbmc idrac9 start --warm --run-as-me >"${TMPDIR:-/tmp}/zbmc-warm-test.$$" 2>&1; then
  echo 'idrac9 unexpectedly accepted --warm' >&2
  exit 1
fi
grep -Fq 'warm restore is broken: restored usb-net is network-dead' "${TMPDIR:-/tmp}/zbmc-warm-test.$$"
rm -f "${TMPDIR:-/tmp}/zbmc-warm-test.$$"

if $repo/tools/zbmc megarac-hpe start --warm --run-as-me >"${TMPDIR:-/tmp}/zbmc-warm-test.$$" 2>&1; then
  echo 'megarac-hpe unexpectedly accepted --warm' >&2
  exit 1
fi
grep -Fq 'warm restore is broken: saved ASPEED SRAM is 0x17000; current model requires 0x18000' "${TMPDIR:-/tmp}/zbmc-warm-test.$$"
rm -f "${TMPDIR:-/tmp}/zbmc-warm-test.$$"

echo 'warm capabilities: PASS'
