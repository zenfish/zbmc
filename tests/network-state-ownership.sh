#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
grep -Fq 'type bridge_slave flood off mcast_flood off bcast_flood on' "$repo/tools/zbmc-net"
grep -Fq 'flower arp_tip "$guest_ip" action pass' "$repo/tools/zbmc-net"
grep -Fq 'flower dst_ip "$guest_ip" action pass' "$repo/tools/zbmc-net"
grep -Fq 'flower dst_mac "$guest_mac" action pass' "$repo/tools/zbmc-net"
grep -Fq 'matchall action drop' "$repo/tools/zbmc-net"
grep -Fq 'add-tap "$tap" "$owner" "$ZBMC_IP" "$ZBMC_MAC"' "$repo/tools/zbmc"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin"

cat >"$tmp/bin/id" <<'EOF'
#!/usr/bin/env bash
[ "$1" = -u ] && echo 0
EOF
cat >"$tmp/bin/ip" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$IP_LOG"
EOF
cat >"$tmp/bin/flock" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "$tmp/bin/id" "$tmp/bin/ip" "$tmp/bin/flock"

cat >"$tmp/net.state" <<'EOF'
UPLINK=eth0
BR=br-zbmc
V4=192.0.2.2/24
GW=192.0.2.1
EOF
printf '%s\n' zbmc-tap0 >"$tmp/net.state.taps"

PATH="$tmp/bin:$PATH" IP_LOG="$tmp/ip.log" ZBMC_NET_STATE="$tmp/net.state" \
  ZBMC_UPLINK=eth0 "$repo/tools/zbmc-net" teardown

grep -Fxq 'link del zbmc-tap0' "$tmp/ip.log"
! grep -Fq unrelated "$tmp/ip.log"
[ ! -e "$tmp/net.state" ] && [ ! -e "$tmp/net.state.taps" ]

echo 'network state ownership: PASS'
