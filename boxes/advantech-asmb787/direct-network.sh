#!/bin/sh
# Emulator-only: skip this firmware's incompatible NC-SI state machine and use
# the already-started FTGMAC data path directly.
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

# ncsi_start_dev(): mov r0,#0; bx lr. The pinned kernel's FTGMAC open path has
# already enabled RX/TX, NAPI, the queue, and carrier before this call.
devmem 0x8098128c 32 0xe3a00000
devmem 0x80981290 32 0xe12fff1e

printf '%s\n' \
    'auto lo' \
    'iface lo inet loopback' \
    '' \
    'auto eth0' \
    'iface eth0 inet static' \
    "    address $ip" \
    '    netmask 255.0.0.0' > "$conf_root/interfaces"
echo "zbmc: Advantech direct FTGMAC address $ip/8"
