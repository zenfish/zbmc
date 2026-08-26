#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
output=$(bash -c '
  _zbmc_resolve_ip(){ echo 127.0.0.1; }
  . "$1"
  zbmc_ssh(){ echo active; }
  _openbmc_retry_net_ipmi "$$"
' bash "$repo/boxes/openbmc/zbmc.box")

[ "$output" = "Network IPMI socket active after SSH became reachable" ]
echo "OpenBMC Network IPMI retry: PASS"
