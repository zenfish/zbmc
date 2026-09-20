#!/bin/sh
# boot-apache-guest.sh — iDRAC10 Phase 2+3 guest-side Apache + Redfish bring-up
#
# WHAT:   Runs inside QEMU npcm845-evb guest (init=/usr/bin/sh) to bring up Apache HTTPS
#         with static JSON for Redfish endpoints (/redfish/v1/ served from /tmp/rf_root.json).
# WHEN:   Called by host expect script after filesystems are mounted + network is configured.
# HOW:    1. Wait for kernel CSPRNG initialization via a blocking /dev/random read
#         2. Download + run setup-apache.sh over the isolated USB network (http://10.0.3.2:8091/)
#         3. Write static Redfish JSON files to /tmp/
#         4. Start Apache HTTPS on port 443
#         5. Poll for port up, report APACHE_READY or APACHE_FAILED
# OUTPUT: Final line is "APACHE_READY" (success) or "APACHE_FAILED" (timeout/crash)
#         Apache error log at /tmp/apache-err.log

HOST_URL="${HOST_URL:-http://10.0.3.2:8091}"

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
printf '%s\n' '{"@odata.id":"/redfish/v1/Systems","@odata.type":"#ComputerSystemCollection.ComputerSystemCollection","Name":"Computer System Collection","Members@odata.count":1,"Members":[{"@odata.id":"/redfish/v1/Systems/System.Embedded.1"}]}' > /tmp/rf_systems.json
printf '%s\n' '{"@odata.id":"/redfish/v1/Systems/System.Embedded.1","@odata.type":"#ComputerSystem.v1_20_0.ComputerSystem","Id":"System.Embedded.1","Name":"System","Manufacturer":"Dell Inc.","Model":"PowerEdge R760","SystemType":"Physical","SKU":"LAB0001","SerialNumber":"LAB0001","PowerState":"Off","Status":{"State":"Enabled","Health":"OK"},"Links":{"ManagedBy":[{"@odata.id":"/redfish/v1/Managers/iDRAC.Embedded.1"}],"Chassis":[{"@odata.id":"/redfish/v1/Chassis/System.Embedded.1"}]}}' > /tmp/rf_system1.json
printf '%s\n' '{"@odata.id":"/redfish/v1/Managers","@odata.type":"#ManagerCollection.ManagerCollection","Name":"Manager Collection","Members@odata.count":1,"Members":[{"@odata.id":"/redfish/v1/Managers/iDRAC.Embedded.1"}]}' > /tmp/rf_managers.json
printf '%s\n' '{"@odata.id":"/redfish/v1/Managers/iDRAC.Embedded.1","@odata.type":"#Manager.v1_19_0.Manager","Id":"iDRAC.Embedded.1","Name":"Manager","ManagerType":"BMC","Model":"iDRAC10","FirmwareVersion":"1.30.10.50","PowerState":"On","Status":{"State":"Enabled","Health":"OK"},"Links":{"ManagerForServers":[{"@odata.id":"/redfish/v1/Systems/System.Embedded.1"}],"ManagerForChassis":[{"@odata.id":"/redfish/v1/Chassis/System.Embedded.1"}]}}' > /tmp/rf_idrac.json
printf '%s\n' '{"@odata.id":"/redfish/v1/Chassis","@odata.type":"#ChassisCollection.ChassisCollection","Name":"Chassis Collection","Members@odata.count":1,"Members":[{"@odata.id":"/redfish/v1/Chassis/System.Embedded.1"}]}' > /tmp/rf_chassis.json
printf '%s\n' '{"@odata.id":"/redfish/v1/Chassis/System.Embedded.1","@odata.type":"#Chassis.v1_25_0.Chassis","Id":"System.Embedded.1","Name":"Computer System Chassis","ChassisType":"RackMount","Manufacturer":"Dell Inc.","Model":"PowerEdge R760","PowerState":"Off","Status":{"State":"Enabled","Health":"OK"},"Links":{"ManagedBy":[{"@odata.id":"/redfish/v1/Managers/iDRAC.Embedded.1"}],"ComputerSystems":[{"@odata.id":"/redfish/v1/Systems/System.Embedded.1"}]}}' > /tmp/rf_chassis1.json
printf '%s\n' '{"@odata.id":"/redfish/v1/AccountService","@odata.type":"#AccountService.v1_15_0.AccountService","Id":"AccountService","Name":"Account Service","ServiceEnabled":true,"Accounts":{"@odata.id":"/redfish/v1/AccountService/Accounts"},"Roles":{"@odata.id":"/redfish/v1/AccountService/Roles"}}' > /tmp/rf_acct.json
printf '%s\n' '{"@odata.id":"/redfish/v1/AccountService/Accounts","@odata.type":"#ManagerAccountCollection.ManagerAccountCollection","Name":"Accounts Collection","Members@odata.count":1,"Members":[{"@odata.id":"/redfish/v1/AccountService/Accounts/1"}]}' > /tmp/rf_accts.json
printf '%s\n' '{"@odata.id":"/redfish/v1/AccountService/Accounts/1","@odata.type":"#ManagerAccount.v1_12_0.ManagerAccount","Id":"1","Name":"User Account","UserName":"root","RoleId":"Administrator","Enabled":true,"Locked":false,"Links":{"Role":{"@odata.id":"/redfish/v1/AccountService/Roles/Administrator"}}}' > /tmp/rf_acct1.json
printf '%s\n' '{"@odata.id":"/redfish/v1/SessionService","@odata.type":"#SessionService.v1_1_9.SessionService","Id":"SessionService","Name":"Session Service","ServiceEnabled":true,"SessionTimeout":1800,"Sessions":{"@odata.id":"/redfish/v1/SessionService/Sessions"}}' > /tmp/rf_session.json
printf '%s\n' '{"@odata.id":"/redfish/v1/UpdateService","@odata.type":"#UpdateService.v1_14_0.UpdateService","Id":"UpdateService","Name":"Update Service","ServiceEnabled":true,"FirmwareInventory":{"@odata.id":"/redfish/v1/UpdateService/FirmwareInventory"}}' > /tmp/rf_update.json
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
