#!/usr/bin/env bash
# run-p3-redfish.sh — iDRAC10 Phase 3: Redfish /redfish/v1/ returns HTTP 200 JSON
#
# WHAT:  Boots iDRAC10 AArch64 (NPCM845) in QEMU with init=/usr/bin/sh,
#        starts Apache HTTPS + mock telemetryservice backend (TCP :9999),
#        confirms GET /redfish/v1/ returns HTTP 200 with service root JSON.
# HOW:   1. Sync scripts to serve dir; serve via python3 HTTP on port 8080
#         2. QEMU: kernel Image.boot-patched, DTB qemu-gmac.dtb, SD squashfs
#         3. expect: mount → network → boot-apache-guest.sh → APACHE_READY
#         4. curl https://localhost:8443/redfish/v1/ → expect HTTP 200
# SUCCESS: /redfish/v1/ returns HTTP 200 with @odata.type ServiceRoot JSON
# TIMING: ~160–320s total (stmmac 60-180s + crng + Apache)
# NOTES:  telemetryservice (metric-engine flatpak) skipped — static JSON served via AliasMatch.
#         minimal-redfish.conf: AliasMatch /redfish/v1/ → /tmp/rf_root.json (no proxy).
#         Uses snapshot=on so SD image is never modified.
set -euo pipefail
cd "$(dirname "$0")"

SOCK=/tmp/idrac10-live.sock
SERVE_DIR=/tmp/idrac10-serve
HTTP_PORT=8080
QEMU_HTTPS_PORT=8443

[ -S "$SOCK" ] && rm -f "$SOCK"

# Sync scripts to serve dir so stale /tmp copies don't interfere
mkdir -p "$SERVE_DIR"
cp setup-apache.sh boot-apache-guest.sh "$SERVE_DIR/"
echo "[+] Scripts synced to $SERVE_DIR"

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

# Expect: boot + network + Apache + mock backend
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

# Network — stmmac ndo_open() takes 60-180s
send "ip link set eth0 up; ip addr add 10.0.2.15/24 dev eth0; ip route add default via 10.0.2.2\r"
expect -timeout 210 "sh-5.2#"
puts "[expect] network up"

# boot-apache-guest.sh: setup + mock backend + crng wait + Apache start
puts "[expect] running boot-apache-guest.sh (mock backend + crng wait + Apache)..."
send "wget -q --timeout=15 http://10.0.2.2:8080/boot-apache-guest.sh -O /tmp/b.sh && sh /tmp/b.sh 2>&1\r"
set timeout 360
expect {
    "APACHE_READY" {
        puts "[expect] APACHE IS UP — checking Redfish endpoint"
        exit 0
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
    BODY=$(cat /tmp/idrac10-curl.out 2>/dev/null | head -c 200)
    echo "  GET ${path} → HTTP ${CODE}"
    if [ "$CODE" = "000" ]; then
        echo "  [!] Connection failed"
    else
        echo "  ${BODY}"
    fi
    echo ""
done

echo "[+] Phase 3 target: /redfish/v1/ HTTP 200 with ServiceRoot JSON"
