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
cat > "$tmp/zbmc" <<'EOF'
_zbmc_resolve_ip(){ echo 127.0.0.1; }
EOF
cat > "$tmp/retry.box" <<'EOF'
_openbmc_retry_net_ipmi(){ echo "retry ran for $1"; }
EOF
mkdir -p "$tmp/run"
ZBMC_DIR="$tmp" ZBMC_RUN_DIR="$tmp/run" _SELF="$tmp" BF="$tmp/retry.box" bash -c '
  _zbmc_resolve_ip(){ echo 127.0.0.1; }
  . "$1"
  zbmc_post_launch "$$"
' bash "$repo/boxes/openbmc/zbmc.box"
for _ in $(seq 1 50); do
  grep -q '^retry ran for ' "$tmp/run/net-ipmi-retry.log" 2>/dev/null && break
  sleep .1
done
grep -q '^Waiting for SSH before Network IPMI retry$' "$tmp/run/net-ipmi-retry.log"
grep -q '^retry ran for ' "$tmp/run/net-ipmi-retry.log"
echo "OpenBMC Network IPMI retry: PASS"
