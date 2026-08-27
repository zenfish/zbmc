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
grep -Fxq 'ZBMC_REQUIRED_SERVICES="ssh ipmi webui"' "$box"
grep -Fxq 'SNAP=svc-snap-full-working.gz' "$box"
grep -Fq 'if [ -n "${ZBMC_WARM:-}" ]' "$box"
grep -Fq 'if=mtd,snapshot=on' "$repo/boxes/supermicro-x14/shell-x14.sh"
grep -Fq 'if=sd,index=2,snapshot=on' "$repo/boxes/supermicro-x14/restore-svc-x14.sh"
grep -Fq 'ConnectTimeout=15' "$box"
grep -Fq 'X14_BOOT_TOKEN=qemu-x14-svc' "$box"
grep -Fq 'BOOT_TOKEN="${X14_BOOT_TOKEN:-qemu-x14-shell}"' "$repo/boxes/supermicro-x14/shell-x14.sh"
grep -Fq 'qemu-x14-ramroot $BOOT_TOKEN loglevel=4' "$repo/boxes/supermicro-x14/shell-x14.sh"

echo "supermicro-x14 health probes and cold service boot: PASS"
