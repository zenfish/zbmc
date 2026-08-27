#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
printf 'openbmc 10.0.7.10\n' >"$tmp/zhosts.txt"

resolve(){
  ZBMC_SOURCE_ONLY=1 ZHOSTS_FILE="$tmp/zhosts.txt" bash -c \
    '. "$1/tools/zbmc"; _zbmc_resolve_ip openbmc 10 192.0.2.10' _ "$repo"
}

[ "$(resolve)" = 10.0.7.10 ]
[ "$(ZBMC_POOL=198.51.100 resolve)" = 198.51.100.10 ]
[ "$(ZBMC_POOL=198.51.100 ZBMC_IP_openbmc=203.0.113.7 resolve)" = 203.0.113.7 ]

rm "$tmp/zhosts.txt"
[ "$(resolve)" = 192.0.2.10 ]

echo "address configuration: PASS"
