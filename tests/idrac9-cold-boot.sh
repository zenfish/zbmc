#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
box="$repo/boxes/idrac9/zbmc.box"

grep -Fq 'warm restore is unsupported: usb-net returns network-dead' "$box"
! grep -q '\$HOME/phd' "$box"
! grep -q '^zbmc_\(snapshot\|restore\)()' "$box"

echo "idrac9 cold-boot contract: PASS"
