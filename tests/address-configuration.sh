#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/repo/tools" "$tmp/repo/boxes"
cp "$repo/tools/zbmc" "$tmp/repo/tools/zbmc"
printf 'openbmc 10.0.7.10\n' >"$tmp/zhosts.txt"

resolve(){
  ZBMC_SOURCE_ONLY=1 ZHOSTS_FILE="$tmp/zhosts.txt" bash -c \
    '. "$1/tools/zbmc"; _zbmc_resolve_ip openbmc 10 192.0.2.10' _ "$tmp/repo"
}

[ "$(resolve)" = 10.0.7.10 ]
[ "$(ZBMC_POOL=198.51.100 resolve)" = 198.51.100.10 ]
[ "$(ZBMC_POOL=198.51.100 ZBMC_IP_openbmc=203.0.113.7 resolve)" = 203.0.113.7 ]

rm "$tmp/zhosts.txt"
[ "$(resolve)" = 192.0.2.10 ]

grep -Fq 'ZBMC_IP="$2"; SSH_PORT="$3"; IPMI_PORT="$4"; WEB_PORT="$5"; qp="$6"' "$repo/tools/zbmc"
grep -Fq 'ZBMC_DIR="$7"; ZBMC_HOST="$8"' "$repo/tools/zbmc"

echo "address configuration: PASS"
