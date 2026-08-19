#!/usr/bin/env bash
# start-web.sh — Phase-6 web/Redfish bring-up for the virtual iDRAC9. Run from the HOST; drives
# the guest over ssh-in.sh. Boot run-p4.sh first WITH a 443 hostfwd (add hostfwd=tcp::6443-:443).
#
# WHAT WORKS (2026-06-28, live-proven — REDFISH-PROOF.txt):
#   TIER A  HTTPS Redfish service root, host-accessible:
#           curl -k https://localhost:6443/redfish/  ->  {"v1":"/redfish/v1/"}
#           /redfish/v1/$metadata, /odata, Schemas, Registries  -> HTTP 200 (static)
#   TIER B  odatalite (fcgiodata@4200) serves LIVE Redfish JSON for /redfish/v1/ → HTTP 200
#           ServiceRoot.json with Links.Systems/Chassis/Managers/SessionService/etc.
#           DONE: 4-byte patch in librootprovider.so (b 0x870 at 0xa30) handles "v1" URI.
#           Patch baked into init.p6.custom (bind-mount over squashfs) — persistent on cold boot.
#           No LD_PRELOAD hook needed: UDB service creates HMC.db; ZMQ stubs not required.
#
# REMAINING (Tier C):
#   - Tier C (authenticated Redfish/GUI/wsman): real fcgi-auth needs the DM/CIAM auth backend
#     (dm-stage2/dm-stage-core); we BYPASS it here (Require all granted for /redfish).
#   - httpd stability: a systemd-managed httpd (httpd.service, Requires= by fcgi-auth) keeps taking
#     over WITHOUT RF_RESPONDER in its env -> rewrite targets fcgi://127.0.0.1:/ -> 'DNS lookup
#     failure'. Workaround below pkills + restarts httpd with RF_RESPONDER=4200. Proper fix: mask
#     httpd.service and own it here, or SetEnv RF_RESPONDER 4200 in a conf drop-in.
#   - Tier C (authenticated Redfish/GUI/wsman): real fcgi-auth needs the DM/CIAM auth backend
#     (dm-stage2/dm-stage-core); we BYPASS it here (Require all granted for /redfish).
#
# KEY UNLOCKS FOUND:
#   1. httpd must start with `-d /` (ServerRoot): conf.d sets ServerRoot=/usr/local/bin but the
#      LoadModule lines run before that with relative lib/apache2/modules/ -> modules are at
#      /lib/apache2/modules (94). Start with -d / so they resolve.
#   2. cert/key: seed self-signed at /flash/data0/etc/certs/CA/certs/host.crt +
#      /flash/data0/cv/private/host.key (hardcoded in conf, absent in extract).
#   3. RF_RESPONDER=4200 MUST be in httpd's env (Redfish rewrite -> fcgi://127.0.0.1:$RF_RESPONDER).
#   4. EVERY request passes the AuthnzFcgi authorizer (fcgi-auth:4300). For /redfish we strip the
#      authorizer (Require all granted) since the CIAM/PAM backend isn't wired in mini.target.
#   5. odatalite (Redfish responder): /usr/bin/fcgiodata, LD_LIBRARY_PATH=/usr/libexec/odatalite,
#      FCGI_ODATA_RESPONDER_PORT=4200, socket-activate on 127.0.0.1:4200.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"; SSH="$HERE/ssh-in.sh"

echo "== 1. seed self-signed cert/key at the iDRAC flash paths =="
"$SSH" 'mkdir -p /flash/data0/etc/certs/CA/certs /flash/data0/cv/private
  [ -s /flash/data0/etc/certs/CA/certs/host.crt ] || openssl req -x509 -newkey rsa:2048 \
    -keyout /flash/data0/cv/private/host.key -out /flash/data0/etc/certs/CA/certs/host.crt \
    -days 3650 -nodes -subj "/C=US/O=Dell/CN=iDRAC-virtual" >/tmp/sslgen.log 2>&1
  chmod 600 /flash/data0/cv/private/host.key; echo "cert seeded"'

echo "== 2. bypass fcgi-auth for /redfish (Require all granted) in the volatile config =="
"$SSH" 'F=/etc/apache2/conf.d/fcgi-auth.conf; sed -n "/<LocationMatch ^\/redfish>/,/<\/LocationMatch>/p" "$F" | grep -q "Require all granted" && { echo "already patched"; exit 0; }
  cp "$F" /tmp/fcgi-auth.conf.bak
  awk "
  /<LocationMatch \\^\\/redfish>/ {inrf=1}
  inrf && /<\\/LocationMatch>/ {inrf=0; print; next}
  inrf {
    if (\$0 ~ /AuthnzFcgiCheckAuthnProvider/) {skip=1}
    if (skip) { if (\$0 !~ /\\\\[ \\t]*\$/) {skip=0}; next }
    if (\$0 ~ /AuthType|AuthName/) next
    if (\$0 ~ /Require fcgi-auth/) {sub(/Require fcgi-auth/,\"Require all granted\")}
  } {print}" /tmp/fcgi-auth.conf.bak > "$F"; echo "auth bypass applied"'

echo "== 3. start backend daemons (best-effort; their listen sockets hang the ssh -> timeout-cap) =="
# odatalite (Redfish responder 4200) + fcgi-rds socket (GUI REST) + fcgi-auth (4300) + fcgi-auth-mut
# (4301; binary /usr/bin/fcgi-auth-mut, NOT fcgi-auth). fcgi-rds.socket via systemd — manual
# socket-activate won't create the AF_UNIX path /run/fcgirds/fcgirds.socket.
timeout 25 "$SSH" 'cat > /tmp/web-daemons.sh <<EOS
#!/bin/sh
export LD_LIBRARY_PATH=/usr/libexec/odatalite FCGI_ODATA_RESPONDER_PORT=4200
mkdir -p /var/lib/odatalite
[ -f /var/lib/odatalite/RedfishIdMappings.db ] || cp -f /usr/share/redfish/RedfishIdMappings.db /var/lib/odatalite/
# libserver-provider.so needs libjob-utils.so; squashfs has it but may be missing from odatalite tmpfs
[ -f /usr/libexec/odatalite/libjob-utils.so ] || cp -f /tmp/libjob-utils.so /usr/libexec/odatalite/ 2>/dev/null || true
pkill -9 -f fcgiodata 2>/dev/null; sleep 1
setsid systemd-socket-activate -l 127.0.0.1:4200 /usr/bin/fcgiodata </dev/null >/tmp/odata.out 2>&1 &
systemctl start fcgi-rds.socket fcgi-auth.socket 2>/dev/null
pkill -9 -f "/usr/bin/fcgi-auth " 2>/dev/null
setsid systemd-socket-activate -l 127.0.0.1:4301 /usr/bin/fcgi-auth-mut </dev/null >/tmp/authmut.out 2>&1 &
EOS
chmod +x /tmp/web-daemons.sh; sh /tmp/web-daemons.sh; sleep 2
echo "odatalite=$(pgrep -fc fcgiodata) rds-sock=$([ -S /run/fcgirds/fcgirds.socket ] && echo Y) authmut=$(pgrep -fc fcgi-auth-mut)"' || echo "(daemon ssh capped — they start detached; normal)"

echo "== 4. apply GUI config edits — NOT capped (tmpfiles re-copies the volatile config + reverts these) =="
# fcgi-auth-mut .html authorizer bypass for /restgui (login UI serves static, no CIAM authorizer)
# + bare-/ -> login redirect. These + the cert are what the login page needs; keep them off the
# hang-prone daemon ssh so they ALWAYS apply. (Re-run this whole script if the web breaks later.)
"$SSH" 'M=/etc/apache2/conf.d/fcgi-auth-mut.conf
grep -q "Require all granted" "$M" || { awk "
  /AuthnzFcgiCheckAuthnProvider/ {skip=1}
  skip { if (\$0 !~ /\\\\[ \t]*\$/) skip=0; next }
  /Require fcgi-auth-mut/ {sub(/Require fcgi-auth-mut/,\"Require all granted\")}
  {print}" "$M" > /tmp/mut.conf && cp /tmp/mut.conf "$M"; echo "fcgi-auth-mut /restgui bypass applied"; }
cat > /tmp/slash.awk <<"AWK"
/<VirtualHost.*SERVER_HTTPS_PORT/ {inv=1}
inv && /RewriteEngine On/ && !d { print; print "    RewriteRule ^/$ /restgui/start.html [R=302,L]   # bare-/ -> login"; d=1; next }
{print}
AWK
V=/etc/apache2/conf.d/03-vhosts.conf
grep -q "bare-/ -> login" "$V" || { awk -f /tmp/slash.awk "$V" > /tmp/vh2.conf && cp /tmp/vh2.conf "$V"; echo "bare-/ redirect applied"; }
G=/etc/apache2/conf.d/httpd_gui.conf   # CSP: AngularJS needs unsafe-eval or browsers block it
grep -q "unsafe-eval" "$G" || { sed -i "s/script-src .self. .unsafe-inline./script-src '"'"'self'"'"' '"'"'unsafe-inline'"'"' '"'"'unsafe-eval'"'"'/" "$G"; echo "CSP unsafe-eval added"; }'

echo "== 5. (re)start httpd with all config in place — NOT capped (httpd -k start daemonizes) =="
"$SSH" 'pkill -9 httpd 2>/dev/null; sleep 2; env RF_RESPONDER=4200 httpd -d / -D SSL -k start 2>&1 | head -1; sleep 3
echo "httpd=$(pgrep -c httpd)  cfg=$(httpd -d / -t 2>&1 | tail -1)"'

echo "== test (poll host) =="
for i in 1 2 3 4 5 6; do
  r=$(timeout -s KILL 8 curl -sk https://localhost:6443/redfish/ 2>/dev/null)
  echo "$r" | grep -q '"v1"' && { echo "Redfish service root UP"; break; }
  sleep 3
done
g=$(timeout -s KILL 8 curl -sk --compressed -o /dev/null -w '%{http_code}' https://localhost:6443/restgui/start.html 2>/dev/null)
echo "GUI login page (/restgui/start.html): HTTP $g  -> browser: https://drac9/restgui/start.html"
echo "  host: curl -k https://localhost:6443/redfish/   (or https://drac9/redfish/ after: zbmc idrac9 net up)"
