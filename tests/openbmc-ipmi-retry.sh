#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
output=$(bash -c '
  _zbmc_resolve_ip(){ echo 127.0.0.1; }
  . "$1"
  zbmc_ssh(){ echo active; }
  _openbmc_retry_net_ipmi "$$"
' bash "$repo/boxes/openbmc/zbmc.box")

[ "$output" = "Network IPMI socket active after SSH became reachable" ]
detached=$(ZBMC_DIR="$tmp" ZBMC_RUN_DIR="$tmp/run" bash -c '
  _zbmc_resolve_ip(){ echo 127.0.0.1; }
  . "$1"
  _openbmc_retry_net_ipmi(){ echo "retry ran for $1"; }
  zbmc_post_launch "$$"
  wait "$(cat "$ZBMC_RUN_DIR/net-ipmi-retry.pid")"
  cat "$ZBMC_RUN_DIR/net-ipmi-retry.log"
' bash "$repo/boxes/openbmc/zbmc.box")
[[ "$detached" == "retry ran for "* ]]
echo "OpenBMC Network IPMI retry: PASS"
