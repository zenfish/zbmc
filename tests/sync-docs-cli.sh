#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/repo/tools"
cp "$repo/tools/sync-docs" "$repo/tools/zmd2html" "$repo/tools/html-to-gfm.lua" "$tmp/repo/tools/"
cd "$tmp/repo"
git init -q
git config user.email test@example.invalid
git config user.name test
printf '# Test\n' > test.md
printf '# Other\n' > other.md
git add .
git commit -qm source

./tools/sync-docs --write test.md >/dev/null 2>&1
[ -f test.html ]
[ ! -e other.html ]
./tools/sync-docs --write other.html >/dev/null 2>&1
./tools/sync-docs test.md other.html >/dev/null 2>&1
git add test.html other.html
git commit -qm pair

printf '\nSource edit.\n' >> test.md
if output=$(./tools/sync-docs test.html 2>&1); then
  echo "targeted check accepted an unsynchronized pair" >&2
  exit 1
fi
grep -Eq '0/1 were fine, 1 has changed and not synced:' <<<"$output"
grep -Fxq 'test.md' <<<"$output"
grep -Fq 'Type "./tools/sync-docs --write test.html" to sync the docs.' <<<"$output"

output=$(./tools/sync-docs --write 2>&1)
grep -Fq 'wrote test.html' <<<"$output"
grep -Fq '2/2 were fine; all documentation pairs are synced.' <<<"$output"

printf '\nAnother source edit.\n' >> test.md
if output=$(./tools/sync-docs 2>&1); then
  echo "default check accepted a second unsynchronized source edit" >&2
  exit 1
fi
grep -Fq '1 has changed and not synced:' <<<"$output"
! grep -Fq 'changed in both source docs' <<<"$output"
./tools/sync-docs --write >/dev/null 2>&1

printf '\nConflicting source edit.\n' >> test.md
printf '\nManual HTML edit.\n' >> test.html
if output=$(./tools/sync-docs 2>&1); then
  echo "default check accepted edits to both sides of a pair" >&2
  exit 1
fi
grep -Fq '1 has changed in both source docs!' <<<"$output"
grep -Fq 'test.md and test.html' <<<"$output"
grep -Fq "You'll have to figure out how to sync test.md and test.html manually." <<<"$output"

echo 'documentation sync CLI: PASS'
