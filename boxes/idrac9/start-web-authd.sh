#!/bin/sh
# Tier-D full authenticated-Redfish bring-up + self-test, run DETACHED on the box
# (survives ssh drops). Writes final result to /tmp/result. Cascade-free: uses
# --job-mode=ignore-dependencies so no dependency pull-in thrash.
exec >/tmp/bringup.log 2>&1
set -x

# 1. creds (idempotent)
racadm set iDRAC.Users.2.UserName root
racadm set iDRAC.Users.2.Password Calvin123#
racadm set iDRAC.Users.2.Enable Enabled
racadm set iDRAC.Users.2.Privilege 0x1ff
racadm set iDRAC.Users.2.IpmiLanPrivilege 4

# 2. httpd.service neutered to sleep (satisfy fcgi-auth Requires, no apache-via-systemd)
mkdir -p /run/systemd/system/httpd.service.d
printf '%s\n' '[Service]' 'Type=simple' 'ExecStartPre=' 'ExecStart=' 'ExecStop=' 'ExecStartPost=' 'ExecStart=/bin/sleep infinity' > /run/systemd/system/httpd.service.d/tierd.conf
systemctl daemon-reload

# 3. backend units, cascade-free (ignore-dependencies = start unit alone, no pull-in)
systemctl start --no-block --job-mode=ignore-dependencies httpd.service
systemctl start --no-block --job-mode=ignore-dependencies unified-database-model.service
systemctl start --no-block --job-mode=ignore-dependencies fcgiodata@4200.socket
systemctl start --no-block --job-mode=ignore-dependencies fcgi-auth.socket

# 4. cert (if missing)
mkdir -p /flash/data0/etc/certs/CA/certs /flash/data0/cv/private
[ -s /flash/data0/etc/certs/CA/certs/host.crt ] || openssl req -x509 -newkey rsa:2048 \
  -keyout /flash/data0/cv/private/host.key -out /flash/data0/etc/certs/CA/certs/host.crt \
  -days 3650 -nodes -subj /CN=idrac-virtual
chmod 600 /flash/data0/cv/private/host.key

# 5. give UDB a moment, then fcgiodata@4200 service (needs UDB up)
sleep 20
systemctl start --no-block --job-mode=ignore-dependencies fcgiodata@4200.service

# 6. manual apache with RF_RESPONDER
sleep 10
pkill -9 httpd; sleep 2
env RF_RESPONDER=4200 httpd -d / -D SSL -k start

# 7. wait for backend READY, then SELF-TEST (guest-side)
sleep 45
{
  echo "no-auth = $(curl -sk -o /dev/null -w '%{http_code}' https://127.0.0.1:443/redfish/v1/Managers)"
  echo "badpw   = $(curl -sk -o /dev/null -w '%{http_code}' -u root:wrongpw https://127.0.0.1:443/redfish/v1/Managers)"
  echo "valid   = $(curl -sk -o /dev/null -w '%{http_code}' -u root:Calvin123# https://127.0.0.1:443/redfish/v1/Managers)"
  echo "sroot-valid = $(curl -sk -o /dev/null -w '%{http_code}' -u root:Calvin123# https://127.0.0.1:443/redfish/v1/)"
  echo "--- valid ServiceRoot body ---"
  curl -sk -u root:Calvin123# https://127.0.0.1:443/redfish/v1/ | head -c 500
  echo
  echo "SHA256=$(racadm get iDRAC.Users.2.SHA256Password 2>/dev/null | grep -i sha256 | cut -d= -f2 | head -c 20)"
  echo ALLDONE
} > /tmp/result 2>&1
