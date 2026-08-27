#!/bin/sh
set -e

# Phase 2+3 Apache + Redfish bring-up for virtual iDRAC10.
# Requires mounted proc/sys/dev/tmp/run/var/volatile/mnt and working guest networking.

setenforce 0 2>/dev/null || true

mkdir -p /var/volatile/apache2/conf.d /var/volatile/log/apache2 /run/apache2

cp /usr/share/factory/etc/apache2/httpd.conf /var/volatile/apache2/
cp /usr/share/factory/etc/apache2/mime.types /var/volatile/apache2/
cp /usr/share/factory/etc/apache2/magic /var/volatile/apache2/ 2>/dev/null || true
for f in 00-base.conf 01-base-idrac-ec-modules.conf 02-httpd-listen.conf \
         03-vhosts.conf mpm-event.conf; do
    cp "/usr/share/factory/etc/apache2/conf.d/$f" /var/volatile/apache2/conf.d/ 2>/dev/null || true
done
cp -r /usr/share/factory/etc/apache2/extra /var/volatile/apache2/ 2>/dev/null || true

# Serve the currently implemented Redfish ServiceRoot as static JSON.
cat > /var/volatile/apache2/conf.d/minimal-redfish.conf << 'RFEOF'
AliasMatch ^/redfish/?$     /tmp/rf_v.json
AliasMatch ^/redfish/v1/?$  /tmp/rf_root.json
<Directory /tmp>
    AllowOverride None
    Require all granted
</Directory>
RFEOF

sed -i '1i Define AVCT_VCONSOLE_PORT 5900' /var/volatile/apache2/httpd.conf
sed -i '1i DefaultRuntimeDir /run/apache2' /var/volatile/apache2/httpd.conf
sed -i '1i ServerRoot "/usr"' /var/volatile/apache2/httpd.conf
sed -i '/^LoadModule cgid_module /d' /var/volatile/apache2/httpd.conf
cat >> /var/volatile/apache2/httpd.conf << 'MODEOF'
LoadModule headers_module    lib/apache2/modules/mod_headers.so
LoadModule alias_module      lib/apache2/modules/mod_alias.so
LoadModule env_module        lib/apache2/modules/mod_env.so
MODEOF
echo 'ServerName localhost' >> /var/volatile/apache2/httpd.conf

mkdir -p /mnt/persistent_data/data0/etc/ssl/certs
cp /usr/share/factory/etc/ssl/openssl.cnf /mnt/persistent_data/data0/etc/ssl/openssl.cnf
cp /usr/share/factory/etc/ssl/fipsmodule.cnf /mnt/persistent_data/data0/etc/ssl/fipsmodule.cnf 2>/dev/null || true

mkdir -p /mnt/persistent_data/data0/etc/certs/CA/certs
mkdir -p /mnt/persistent_data/data0/cv/private
mkdir -p /mnt/persistent_data/data0/features
echo 'idrac-standalone' > /mnt/persistent_data/data0/features/system-name

/usr/bin/openssl req -x509 -newkey rsa:2048 -sha256 -nodes -days 3650 \
    -subj '/CN=idrac10-virtual/O=LAB/C=US' \
    -keyout /mnt/persistent_data/data0/cv/private/host.key \
    -out /mnt/persistent_data/data0/etc/certs/CA/certs/host.crt
chmod 0600 /mnt/persistent_data/data0/cv/private/host.key

echo "SETUP_COMPLETE"
