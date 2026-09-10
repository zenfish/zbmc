#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
out=$($repo/tools/zbmc list)

grep -Eq '^NAME +RESERVED IP +NETWORK +WARM$' <<<"$out"
grep -Eq '^idrac10 +[^ ]+ +TAP/DIRECT-L2 +(READY|MISSING)$' <<<"$out"
grep -Eq '^megarac-hpe +[^ ]+ +TAP/DIRECT-L2 +BROKEN$' <<<"$out"
grep -Eq '^supermicro-x14 +[^ ]+ +TAP/DIRECT-L2 +BROKEN$' <<<"$out"
grep -Eq '^idrac9 +[^ ]+ +TAP/DIRECT-L2 +BROKEN$' <<<"$out"
grep -Eq '^openbmc +[^ ]+ +TAP/DIRECT-L2 +UNAVAILABLE$' <<<"$out"

for box in "$repo"/boxes/*/zbmc.box; do
  grep -Eq '^ZBMC_NETWORK_MODE=(user|tap)$' "$box" || { echo "network mode missing: $box" >&2; exit 1; }
done
! grep -Fq 'warm-20260831/state.gz' "$repo/boxes/idrac10/build.sh"

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
