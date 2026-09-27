#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
ZBMC_SOURCE_ONLY=1 . "$repo/tools/zbmc"
ZBMC_IP=192.0.2.50
WEB_PORT=443
IPMI_USER=admin
IPMI_PW=superuser
IPMI_KEY=0123abcd
IPMI_OPTS='-C 17 -I lanplus'

[ "$(_ipmi_invocation pw)" = 'zipmi -H 192.0.2.50 -U admin -P superuser -C 17 -I lanplus' ]
[ "$(_ipmi_invocation key)" = 'zipmi -H 192.0.2.50 -U admin -K 0123abcd -C 17 -I lanplus' ]
zbmc_redfish_health() { echo verified; }
[ "$(_probe_redfish)" = 'ok|curl -sk -u admin:superuser https://192.0.2.50:443/redfish/v1/|verified' ]

IPMI_PW="a b'c"
printf -v quoted_pw '%q' "$IPMI_PW"
printf -v quoted_auth '%q' "$IPMI_USER:$IPMI_PW"
[[ "$(_ipmi_invocation pw)" == *"-P $quoted_pw -C 17 -I lanplus" ]]
[[ "$(_probe_redfish)" == *"-u $quoted_auth https://192.0.2.50:443/redfish/v1/|verified" ]]
unset -f zbmc_redfish_health
timeout() { printf '{"RedfishVersion":"1.0"}\n'; }
[[ "$(_probe_redfish)" == *"-u $quoted_auth https://192.0.2.50:443/redfish/v1/|" ]]

lock_dir=$(mktemp -d)
trap 'rm -f "$lock_dir/test-box.ipmi"; rmdir "$lock_dir"' EXIT
ZBMC_PROBE_LOCK_DIR=$lock_dir
ZBMC_NAME=test-box
python3() { return 1; }
ipmitool() { :; }
timeout() { echo Manufacturer; }
[[ "$(_probe_ipmi)" == *"-U admin -P $quoted_pw mc info|" ]]

echo 'credential display: PASS'
