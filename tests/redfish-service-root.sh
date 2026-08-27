#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
status="$repo/tools/zbmc"
x10="$repo/boxes/supermicro-x10/zbmc.box"

grep -q 'local url="https://\$ZBMC_IP:\${WEB_PORT:-443}/redfish/v1/"' "$status"
grep -q 'grep -qi '\''"RedfishVersion"'\''' "$status"
grep -q 'https://\$ZBMC_IP:\${WEB_PORT:-443}/redfish/v1/" 2>/dev/null' "$x10"
grep -q 'grep -q '\''"RedfishVersion"'\''' "$x10"
! grep -q '/redfish/v1/Managers' "$status"
grep -Fq '2??|3??) echo "ok|' "$status"
grep -Fq '*) echo "fail||HTTP $code from $(hostname -s)"' "$status"

echo "Redfish service-root probes: PASS"
