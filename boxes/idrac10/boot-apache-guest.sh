#!/bin/sh
# boot-apache-guest.sh — iDRAC10 Phase 2+3 guest-side Apache + Redfish bring-up
#
# WHAT:   Runs inside QEMU npcm845-evb guest (init=/usr/bin/sh) to bring up Apache HTTPS
#         with static JSON for Redfish endpoints (/redfish/v1/ served from /tmp/rf_root.json).
# WHEN:   Called by host expect script after filesystems are mounted + network is configured.
# HOW:    1. Wait for kernel CSPRNG initialization via a blocking /dev/random read
#         2. Download + run setup-apache.sh from host (http://10.0.2.2:8091/)
#         3. Write static Redfish JSON files to /tmp/
#         4. Start Apache HTTPS on port 443
#         5. Poll for port up, report APACHE_READY or APACHE_FAILED
# OUTPUT: Final line is "APACHE_READY" (success) or "APACHE_FAILED" (timeout/crash)
#         Apache error log at /tmp/apache-err.log

HOST_URL="${HOST_URL:-http://10.0.2.2:8091}"

echo "=== WAITING FOR CSPRNG (crng init done) ==="
head -c 1 /dev/random > /dev/null
echo "=== CSPRNG READY ==="

echo "=== DOWNLOADING SETUP SCRIPT ==="
wget -q --timeout=15 "${HOST_URL}/setup-apache.sh" -O /tmp/s.sh || {
    echo "APACHE_FAILED: wget setup-apache.sh"
    exit 1
}
sh /tmp/s.sh > /tmp/apache-setup.log 2>&1 || {
    echo "APACHE_FAILED: setup-apache.sh"
    exit 1
}
echo "=== SETUP COMPLETE ==="

# Override ErrorLog so we capture Apache logs even if /var/log symlink is missing
echo 'ErrorLog /tmp/apache-err.log' >> /var/volatile/apache2/httpd.conf
echo 'LogLevel warn' >> /var/volatile/apache2/httpd.conf

echo "=== WRITING REDFISH STATIC JSON ==="
# telemetryservice (metric-engine flatpak) has too many deps to start live.
# Use AliasMatch in minimal-redfish.conf to serve these static JSON files directly.
printf '{"v1":"/redfish/v1/"}\n' > /tmp/rf_v.json
printf '{"@odata.context":"/redfish/v1/$metadata#ServiceRoot.ServiceRoot","@odata.id":"/redfish/v1/","@odata.type":"#ServiceRoot.v1_17_1.ServiceRoot","Id":"RootService","Name":"Root Service","RedfishVersion":"1.21.0","UUID":"00000000-0000-0000-0000-000000000000","Systems":{"@odata.id":"/redfish/v1/Systems"},"Chassis":{"@odata.id":"/redfish/v1/Chassis"},"Managers":{"@odata.id":"/redfish/v1/Managers"},"SessionService":{"@odata.id":"/redfish/v1/SessionService"},"AccountService":{"@odata.id":"/redfish/v1/AccountService"},"UpdateService":{"@odata.id":"/redfish/v1/UpdateService"},"CertificateService":{"@odata.id":"/redfish/v1/CertificateService"},"Links":{"Sessions":{"@odata.id":"/redfish/v1/SessionService/Sessions"}}}\n' > /tmp/rf_root.json
echo "=== STATIC JSON READY ==="

echo "=== STARTING APACHE ==="
nohup /usr/sbin/httpd -f /etc/apache2/httpd.conf -DFOREGROUND \
    > /tmp/apache-out.log 2>&1 &
HPID=$!
echo "HTTPD_PID=$HPID"

# Wait for port 443 to appear (tcp6 ::0:01BB)
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    if grep -qE '01BB' /proc/net/tcp /proc/net/tcp6 2>/dev/null; then
        echo "=== PORT 443 UP (iteration $i) ==="
        echo "APACHE_READY"
        exit 0
    fi
    sleep 3
done

# Timeout — dump diagnostics
echo "=== APACHE_FAILED: port 443 not up after 60s ==="
echo "--- apache-out.log ---"
cat /tmp/apache-out.log 2>/dev/null
echo "--- apache-err.log ---"
cat /tmp/apache-err.log 2>/dev/null | tail -10
echo "--- ps ---"
ps | grep httpd || true
echo "APACHE_FAILED"
exit 1
