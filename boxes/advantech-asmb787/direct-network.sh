#!/bin/sh
# Emulator-only: assign the requested address to the DT-selected direct-PHY
# FTGMAC interface before the vendor networking script runs.
set -eu

[ "${1:-}" = start ] || exit 0
proc_root=${ZBMC_PROC_ROOT:-/proc}
conf_root=${ZBMC_CONF_ROOT:-/conf}
ip=$(sed -n 's/.* zbmc_asmb787_ip=\([^ ]*\).*/\1/p' "$proc_root/cmdline")
[ -n "$ip" ] || exit 0
grep -q '5.4.11-ami' "$proc_root/version" || {
    echo 'zbmc: refusing Advantech NC-SI patch on an unknown kernel' >&2
    exit 1
}

# The factory firewall explicitly drops IPv4 echo requests. Remove only that
# rule from the active filter and its persisted copy so later restores agree.
iptables -D INPUT -p icmp -m icmp --icmp-type 8 -j DROP
sed -i '/^-A INPUT -p icmp -m icmp --icmp-type 8 -j DROP$/d' "$conf_root/iptables.conf"

printf '%s\n' \
    'auto lo' \
    'iface lo inet loopback' \
    '' \
    'auto eth0' \
    'iface eth0 inet static' \
    "    address $ip" \
    '    netmask 255.0.0.0' > "$conf_root/interfaces"
echo "zbmc: Advantech direct-PHY FTGMAC address $ip/8"
