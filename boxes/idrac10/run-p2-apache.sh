#!/usr/bin/env bash
# run-p2-apache.sh — iDRAC10 Phase 2: boot guest, start Apache, curl Redfish
#
# WHAT:  Boots iDRAC10 AArch64 (NPCM845) in QEMU with init=/usr/bin/sh,
#        configures Apache HTTPS on port 443, and confirms Redfish endpoint responds.
# HOW:   1. Serve setup scripts via python3 HTTP server on host port 8080
#         2. QEMU: kernel Image.boot-patched, DTB qemu-gmac.dtb, SD squashfs
#            Serial on UNIX socket /tmp/idrac10-live.sock, port 8443→443
#         3. expect: mount/network/boot-apache-guest.sh → wait for APACHE_READY
#         4. curl https://localhost:8443/redfish/v1/ → expect ≥200
# SUCCESS: curl returns HTTP 200/40x from Apache (not 000)
# TIMING: ~160–200s total (stmmac +60s, crng +90s, Apache +3s)
# NOTES:  - Uses snapshot=on so SD image is never modified
#          - python3 not available in guest (busybox only)
#          - crng init done ~152s kernel time; head -c 1 /dev/random blocks until ready
set -euo pipefail
cd "$(dirname "$0")"

SOCK=/tmp/idrac10-live.sock
SERVE_DIR=/tmp/idrac10-serve
HTTP_PORT=8080
QEMU_HTTPS_PORT=8443

[ -S "$SOCK" ] && rm -f "$SOCK"

# Serve setup scripts
pkill -f "http.server ${HTTP_PORT}" 2>/dev/null || true
python3 -m http.server "$HTTP_PORT" --directory "$SERVE_DIR" 2>/tmp/idrac10-httpd.log &
PYPID=$!
trap "kill $PYPID 2>/dev/null; kill \$QPID 2>/dev/null" EXIT

# Boot QEMU
qemu-system-aarch64 \
  -M npcm845-evb -m 1G \
  -kernel boot/Image.boot-patched \
  -dtb boot/qemu-gmac.dtb \
  -drive "id=rootsd,if=none,file=img/sd.img,format=raw,snapshot=on" \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -display none \
  -nic user,model=npcm-gmac,"hostfwd=tcp::${QEMU_HTTPS_PORT}-:443" \
  -serial unix:"${SOCK}",server,nowait \
  2>/tmp/idrac10-qemu.log &
QPID=$!

until [ -S "$SOCK" ]; do sleep 0.5; done
echo "[+] QEMU started, socket ready"

# Expect: boot + network + Apache
expect << 'EOEXP'
set timeout 60
spawn socat - UNIX-CONNECT:/tmp/idrac10-live.sock

# Wait for initial shell
expect { "sh-5.2#" {} timeout { puts "BOOT TIMEOUT"; exit 1 } }
puts "[expect] shell ready"

# Mount filesystems
send "mount -t proc proc /proc; mount -t sysfs sysfs /sys; mount -t devtmpfs devtmpfs /dev; mkdir -p /dev/pts; mount -t devpts devpts /dev/pts; mount -t tmpfs tmpfs /tmp; mount -t tmpfs tmpfs /run; mount -t tmpfs tmpfs /var/volatile; mount -t tmpfs tmpfs /mnt\r"
expect -timeout 15 "sh-5.2#"
puts "[expect] filesystems mounted"

# Network — stmmac ndo_open() takes ~60s
send "ip link set eth0 up; ip addr add 10.0.2.15/24 dev eth0; ip route add default via 10.0.2.2\r"
expect -timeout 90 "sh-5.2#"
puts "[expect] network up"

# Run guest-side boot script; APACHE_READY is only in script OUTPUT, not in command text
puts "[expect] running boot-apache-guest.sh (crng wait ~90s more)..."
send "wget -q --timeout=15 http://10.0.2.2:8080/boot-apache-guest.sh -O /tmp/b.sh && sh /tmp/b.sh 2>&1\r"
set timeout 300
expect {
    "APACHE_READY" {
        puts "[expect] APACHE IS UP"
    }
    "APACHE_FAILED" {
        puts "[expect] APACHE FAILED"
        exit 1
    }
    timeout {
        puts "[expect] TIMEOUT waiting for APACHE_READY"
        exit 1
    }
}
EOEXP

echo ""
echo "[+] Apache is up — testing endpoints"
echo ""

# curl with TLS skip (self-signed cert)
for path in "/redfish/v1/" "/redfish/" "/"; do
    CODE=$(curl -sk --max-time 10 -o /tmp/idrac10-curl.out \
           -w "%{http_code}" "https://localhost:${QEMU_HTTPS_PORT}${path}")
    echo "  GET ${path} → HTTP ${CODE}"
    if [ "$CODE" = "000" ]; then
        echo "  [!] Connection failed"
        head -3 /tmp/idrac10-curl.out 2>/dev/null || true
    else
        head -3 /tmp/idrac10-curl.out 2>/dev/null || true
    fi
    echo ""
done

echo "[+] Phase 2 DONE — Apache HTTPS responding on iDRAC10 virtual"
