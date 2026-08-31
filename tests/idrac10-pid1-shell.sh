#!/usr/bin/env bash
set -euo pipefail

script="$(dirname "$0")/../boxes/idrac10/boot-fullfw-guest.sh"
box="$(dirname "$0")/../boxes/idrac10/zbmc.box"
driver="$(dirname "$0")/../boxes/idrac10/boot-idrac10.exp"
overlay="$(dirname "$0")/../boxes/idrac10/qemu-usb-net-overlay.dts"
qemu_patch="$(dirname "$0")/../boxes/idrac10/qemu-usb-net-high-speed.patch"
apache_boot="$(dirname "$0")/../boxes/idrac10/boot-apache-guest.sh"
apache_setup="$(dirname "$0")/../boxes/idrac10/setup-apache.sh"
sh -n "$script"
sh -n "$apache_boot" "$apache_setup"
grep -q 'PasswordAuthentication no' "$script"
grep -q 'operator.pub' "$script"
grep -q -- '--prefix=/run/dm --prefix=/flash/data0/config' "$script"
grep -q 'cp -a /flash/pd0/ipmi/evb/.' "$script"
tail -n 12 "$script" | grep -q '^while :; do$'
tail -n 12 "$script" | grep -q '^    /bin/sh || true$'
if tail -n 12 "$script" | grep -q '^exit '; then
    echo "boot script still exits to PID 1" >&2
    exit 1
fi
grep -A5 '^zbmc_ssh()' "$box" | grep -q 'ssh/operator'
grep -A5 '^zbmc_console()' "$box" | grep -q 'socat'
! grep -q 'pkill .*fullfw' "$driver"
grep -q 'usb@f0828100' "$overlay"
grep -q 'lpc-kcs@f0007000' "$overlay"
grep -q 'compatible = "nuvoton,npcm750-kcs-bmc"' "$overlay"
grep -q 'target-path = "/cpus"' "$overlay"
[ "$(grep -c 'cpu@[123] {' "$overlay")" -eq 3 ]
[ "$(grep -c 'enable-method = "psci"' "$overlay")" -eq 3 ]
grep -q -- '-device usb-net,netdev=tcpnet,bus=usb-bus.0,port=1' "$box"
grep -q 'qemu/runtime/qemu-system-aarch64' "$box"
grep -q 'ZBMC_QEMU_SHA256=c4a28a5e76492d50abc977e8f2bb57ddac48fca9e32b9350573ff67ffe9cfc45' "$box"
grep -q 'ZBMC_QEMU_MAJOR=11' "$box"
grep -q 'warm restore is not a supported packaged path' "$box"
grep -q 'ZBMC_REQUIRED_SERVICES="ssh ipmi redfish"' "$box"
grep -q 'payload/cfgdb-defaults.sql' "$box"
grep -q 'ssh/operator' "$box"
grep -q 'boot-apache-guest.sh setup-apache.sh' "$box"
grep -q 'mc info 2>&1' "$box"
grep -q 'http://10.0.2.2:8091/boot-apache-guest.sh' "$box"
grep -q '/usr/bin/openssl req -x509 -newkey rsa:2048' "$apache_setup"
! grep -q 'BEGIN .*PRIVATE KEY' "$apache_setup"
[ "$(grep -n 'head -c 1 /dev/random' "$apache_boot" | cut -d: -f1)" -lt "$(grep -n 'sh /tmp/s.sh' "$apache_boot" | cut -d: -f1)" ]
grep -q -- '--warm) ZBMC_WARM=1' "$(dirname "$0")/../tools/zbmc"
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
grep -q 'ip route replace default via 10.0.3.2' "$driver"
grep -q 'ip rule add from 10.0.3.15/32 table 100' "$driver"
grep -q "printf '__ZBMC_%s__" "$driver"

echo "idrac10 access paths, USB TCP network, and PID 1 shell supervision: PASS"
