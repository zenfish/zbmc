#!/usr/bin/env bash
set -euo pipefail

script="$(dirname "$0")/../boxes/idrac10/boot-fullfw-guest.sh"
box="$(dirname "$0")/../boxes/idrac10/zbmc.box"
driver="$(dirname "$0")/../boxes/idrac10/boot-idrac10.exp"
overlay="$(dirname "$0")/../boxes/idrac10/qemu-usb-net-overlay.dts"
qemu_patch="$(dirname "$0")/../boxes/idrac10/qemu-usb-net-high-speed.patch"
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
grep -q 'target-path = "/cpus"' "$overlay"
[ "$(grep -c 'cpu@[123] {' "$overlay")" -eq 3 ]
[ "$(grep -c 'enable-method = "psci"' "$overlay")" -eq 3 ]
grep -q -- '-device usb-net,netdev=tcpnet,bus=usb-bus.0,port=1' "$box"
grep -q '/home/zen/opt/qemu-11-idrac10/bin/qemu-system-aarch64' "$box"
grep -q '^+static const USBDescDevice desc_device_net_high' "$qemu_patch"
[ "$(grep -c '^+.*wMaxPacketSize.*= 0x200' "$qemu_patch")" -eq 4 ]
[ "$(grep -c '^+.*bInterval.*= 9' "$qemu_patch")" -eq 2 ]
[ "$(grep -c '^+.*p->ep->max_packet_size' "$qemu_patch")" -eq 2 ]
grep -q '^+    uc->handle_attach  = usb_desc_attach;' "$qemu_patch"
grep -q 'hostfwd=udp:.*10.0.2.15:623' "$box"
grep -q 'pgrep -f "hostfwd=udp:\$ZBMC_IP:623-"' "$box"
grep -q 'hostfwd=tcp:.*10.0.3.15:22' "$box"
grep -q 'for {set i 0} {\$i < 30' "$driver"
grep -q 'send "\\r"' "$driver"
grep -q 'TCP_NIC=usb0' "$driver"
grep -q 'ip addr add 10.0.3.15/24' "$driver"
grep -q "printf '__ZBMC_%s__" "$driver"

echo "idrac10 access paths, USB TCP network, and PID 1 shell supervision: PASS"
