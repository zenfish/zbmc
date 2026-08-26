#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
box="$repo/boxes/supermicro-x14/zbmc.box"

output=$(bash -c '
  _zbmc_resolve_ip(){ echo 127.0.0.1; }
  . "$1"
  zbmc_ipmi(){ printf "Medium type : 802.3 LAN\\n"; }
  zbmc_ipmi_health
' bash "$box")
[[ "$output" == "AUTH OK (zipmi RMCP+;"* ]]
grep -Fq 'timeout -s KILL "$((probe_timeout + 1))" curl -sk --max-time "$probe_timeout"' "$repo/tools/zbmc"
grep -Fq 'timeout -s KILL "${ZBMC_SSH_PROBE_TIMEOUT:-10}" bash -c "$cmd"' "$repo/tools/zbmc"
grep -Fxq 'ZBMC_SSH_PROBE_TIMEOUT=18' "$box"
grep -Fxq 'ZBMC_HTTP_PROBE_TIMEOUT=18' "$box"
grep -Fq 'ConnectTimeout=15' "$box"

echo "supermicro-x14 IPMI health and HTTP probe deadlines: PASS"
