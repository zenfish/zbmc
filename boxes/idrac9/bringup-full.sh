export RACADM_ACCESS=0x1FF USER=root LC_USERNAME=root REMOTE_USERNAME=root LOGNAME=root
racadm set iDRAC.Users.2.UserName root >/dev/null 2>&1
r=0; while [ $r -lt 6 ]; do racadm set iDRAC.Users.2.Password Calvin123# >/dev/null 2>&1; sleep 3; H=$(racadm get iDRAC.Users.2.SHA256Password 2>/dev/null|grep -i sha|cut -d= -f2); [ -n "$H" ] && break; r=$((r+1)); done
racadm set iDRAC.Users.2.Enable Enabled >/dev/null 2>&1
racadm set iDRAC.Users.2.Privilege 0x1ff >/dev/null 2>&1
echo "SHA256=$(racadm get iDRAC.Users.2.SHA256Password 2>/dev/null|grep -i sha|cut -d= -f2|head -c16)"
mkdir -p /run/systemd/system/httpd.service.d
printf '[Service]\nType=simple\nExecStart=\nExecStart=/bin/sleep infinity\n' > /run/systemd/system/httpd.service.d/tierd.conf
systemctl daemon-reload
systemctl start --no-block --job-mode=ignore-dependencies unified-database-model.service
systemctl start --no-block --job-mode=ignore-dependencies fcgiodata@4200.socket
systemctl start --no-block --job-mode=ignore-dependencies fcgi-auth.socket
mkdir -p /flash/data0/etc/certs/CA/certs /flash/data0/cv/private
[ -s /flash/data0/etc/certs/CA/certs/host.crt ] || openssl req -x509 -newkey rsa:2048 -keyout /flash/data0/cv/private/host.key -out /flash/data0/etc/certs/CA/certs/host.crt -days 3650 -nodes -subj /CN=idrac >/dev/null 2>&1
sleep 18
systemctl start --no-block --job-mode=ignore-dependencies fcgiodata@4200.service
systemctl stop httpd.service 2>/dev/null; pkill -9 httpd 2>/dev/null; sleep 2
env RF_RESPONDER=4200 httpd -d / -D SSL -k start
n=0; while [ $n -lt 25 ]; do code=$(curl -sk -o /dev/null -w '%{http_code}' https://127.0.0.1:443/redfish/v1/Managers 2>/dev/null); [ "$code" != "000" ] && [ -n "$code" ] && break; pkill -9 httpd 2>/dev/null; sleep 2; env RF_RESPONDER=4200 httpd -d / -D SSL -k start; n=$((n+1)); sleep 6; done
echo "backend code=$code after ${n} restarts"
echo "RESULT:"
echo "  no-auth = $(curl -sk -o /dev/null -w '%{http_code}' https://127.0.0.1:443/redfish/v1/Managers)  (expect 401)"
echo "  badpw   = $(curl -sk -o /dev/null -w '%{http_code}' -u root:wrongpw https://127.0.0.1:443/redfish/v1/Managers)  (expect 401)"
echo "  valid   = $(curl -sk -o /dev/null -w '%{http_code}' -u root:Calvin123# https://127.0.0.1:443/redfish/v1/Managers)  (expect 200)"
echo "  sroot   = $(curl -sk -o /dev/null -w '%{http_code}' -u root:Calvin123# https://127.0.0.1:443/redfish/v1/)  (expect 200)"
echo "  body: $(curl -sk -u root:Calvin123# https://127.0.0.1:443/redfish/v1/ 2>/dev/null | tr -d '\n' | head -c 200)"
