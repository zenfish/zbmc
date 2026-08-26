#!/usr/bin/env bash
set -euo pipefail

script="$(dirname "$0")/../boxes/idrac10/boot-fullfw-guest.sh"
box="$(dirname "$0")/../boxes/idrac10/zbmc.box"
driver="$(dirname "$0")/../boxes/idrac10/boot-idrac10.exp"
overlay="$(dirname "$0")/../boxes/idrac10/qemu-usb-net-overlay.dts"
sh -n "$script"
grep -q 'PasswordAuthentication yes' "$script"
tail -n 12 "$script" | grep -q '^while :; do$'
tail -n 12 "$script" | grep -q '^    /bin/sh || true$'
if tail -n 12 "$script" | grep -q '^exit '; then
    echo "boot script still exits to PID 1" >&2
    exit 1
fi
grep -A5 '^zbmc_ssh()' "$box" | grep -q 'sshpass'
grep -A5 '^zbmc_console()' "$box" | grep -q 'socat'
grep -A8 '^zbmc_ipmi_health()' "$box" | grep -q 'raw 0x06 0x3b 0x04'
! grep -q 'pkill .*fullfw' "$driver"
grep -q 'usb@f0828100' "$overlay"
grep -q -- '-device usb-net,netdev=tcpnet,bus=usb-bus.0' "$box"
grep -q 'hostfwd=udp:.*10.0.2.15:623' "$box"
grep -q 'hostfwd=tcp:.*10.0.3.15:22' "$box"
grep -q 'ip addr add 10.0.3.15/24' "$driver"

echo "idrac10 access paths, USB TCP network, and PID 1 shell supervision: PASS"
