#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

touch "$tmp/ilo5_241.bin"
output=$("$repo/tools/unpack-ilo5" "$tmp/ilo5_241.bin")
grep -Fq 'format:  bin' <<<"$output"
grep -Fq 'check: ready; use --write to unpack' <<<"$output"
[ ! -e "$tmp/ilo5_241.unpacked" ]

echo "PASS: unpack-ilo5 defaults to a read-only dependency and input check"
