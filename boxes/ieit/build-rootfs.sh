#!/usr/bin/env bash
set -euo pipefail

ORIGINAL_CRAMFS=${1:?original CramFS required}
CONF_SOURCE=${2:?configuration tree required}
WEB_SOURCE=${3:?Web-UI tree required}
STAGE=${4:?staging directory required}
OUTPUT_CRAMFS=${5:?output CramFS required}
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT=$STAGE/rootfs
VERIFY=$STAGE/verify
RAMDISK_LIMIT=$((35840 * 1024))

mkdir -p "$STAGE"
fsck.cramfs --extract="$ROOT" "$ORIGINAL_CRAMFS"
test -x "$ROOT/sbin/init"
test -x "$ROOT/bin/sh"
test "$(readlink "$ROOT/etc/rcS.d/S06mountall.sh")" = ../init.d/mountall.sh
test "$(readlink "$ROOT/etc/rcS.d/S38ncsicfg.sh")" = ../init.d/ncsicfg.sh
test "$(readlink "$ROOT/etc/rcS.d/S40phycfg.sh")" = ../init.d/phycfg.sh

mkdir -p "$ROOT/zbmc-seed/conf"
cp -a "$CONF_SOURCE/." "$ROOT/zbmc-seed/conf/"
find "$ROOT/zbmc-seed/conf" -type d -exec chmod 0755 {} +
find "$ROOT/zbmc-seed/conf" -type f -exec chmod 0644 {} +
find "$ROOT/zbmc-seed/conf" -type f \
    \( -name '*key*' -o -name '*.pem' -o -name '*.p12' \) -exec chmod 0600 {} +

mv "$ROOT/etc/init.d/mountall.sh" "$ROOT/etc/init.d/mountall.vendor.sh"
install -m 0755 "$HERE/rootfs-overlay/zbmc-runtime.sh" "$ROOT/etc/init.d/zbmc-runtime.sh"
install -m 0755 "$HERE/rootfs-overlay/mountall-wrapper.sh" "$ROOT/etc/init.d/mountall.sh"
install -m 0644 "$HERE/rootfs-overlay/interfaces" "$ROOT/zbmc-seed/conf/interfaces"
mv "$ROOT/etc/init.d/ncsicfg.sh" "$ROOT/etc/init.d/ncsicfg.vendor.sh"
install -m 0755 "$HERE/rootfs-overlay/ncsicfg-wrapper.sh" "$ROOT/etc/init.d/ncsicfg.sh"
mv "$ROOT/etc/init.d/phycfg.sh" "$ROOT/etc/init.d/phycfg.vendor.sh"
install -m 0755 "$HERE/rootfs-overlay/phycfg-wrapper.sh" "$ROOT/etc/init.d/phycfg.sh"

# The vendor diagnostic requires the physical board EEPROM and host complex. Its
# procmonitor registration turns repeated hardware-only exits into a BMC reboot.
mv "$ROOT/etc/init.d/commerDiagnoseServer" \
    "$ROOT/etc/init.d/commerDiagnoseServer.vendor.sh"
install -m 0755 "$HERE/rootfs-overlay/commerDiagnoseServer-wrapper.sh" \
    "$ROOT/etc/init.d/commerDiagnoseServer"

# These applications register with procmonitor and then exit when the host
# complex is absent. After 15 respawns procmonitor reboots the entire BMC.
for service in commer_server commer_poweroffscan_server commerSelfManagerServer; do
    mv "$ROOT/etc/init.d/$service" "$ROOT/etc/init.d/$service.vendor.sh"
    install -m 0755 "$HERE/rootfs-overlay/host-complex-wrapper.sh" \
        "$ROOT/etc/init.d/$service"
done

# The preserved Web-UI is a separate firmware CramFS. The legacy Java remote-console
# clients exceed this kernel's ramdisk ceiling; the HTML5 UI and KVM client remain.
rmdir "$ROOT/usr/local/www"
mkdir -p "$ROOT/usr/local/www"
tar -C "$WEB_SOURCE" --exclude './Java' -cf - . | tar -C "$ROOT/usr/local/www" -xf -
find "$ROOT/usr/local/www" -type d -exec chmod 0755 {} +
find "$ROOT/usr/local/www" -type f -exec chmod 0644 {} +

mkfs.cramfs "$ROOT" "$OUTPUT_CRAMFS"
cramfs_size=$(stat -c %s "$OUTPUT_CRAMFS")
if [ "$cramfs_size" -gt "$RAMDISK_LIMIT" ]; then
    printf 'IEIT service CramFS is %s bytes; kernel limit is %s bytes\n' \
        "$cramfs_size" "$RAMDISK_LIMIT" >&2
    exit 1
fi

fsck.cramfs --extract="$VERIFY" "$OUTPUT_CRAMFS"
test -x "$VERIFY/sbin/init"
test -x "$VERIFY/etc/init.d/mountall.vendor.sh"
test -x "$VERIFY/etc/init.d/zbmc-runtime.sh"
test -x "$VERIFY/etc/init.d/ncsicfg.vendor.sh"
test -x "$VERIFY/etc/init.d/phycfg.vendor.sh"
test -x "$VERIFY/etc/init.d/commerDiagnoseServer.vendor.sh"
test -x "$VERIFY/etc/init.d/commer_server.vendor.sh"
test -x "$VERIFY/etc/init.d/commer_poweroffscan_server.vendor.sh"
test -x "$VERIFY/etc/init.d/commerSelfManagerServer.vendor.sh"
grep -q 'CommerDiagnose disabled' "$VERIFY/etc/init.d/commerDiagnoseServer"
grep -q 'host power/PCIe/ME hardware is not modeled' "$VERIFY/etc/init.d/commer_server"
grep -q 'host power/PCIe/ME hardware is not modeled' "$VERIFY/etc/init.d/commer_poweroffscan_server"
grep -q 'host power/PCIe/ME hardware is not modeled' "$VERIFY/etc/init.d/commerSelfManagerServer"
test "$(readlink "$VERIFY/etc/rcS.d/S06mountall.sh")" = ../init.d/mountall.sh
test "$(readlink "$VERIFY/etc/rcS.d/S46commerDiagnoseServer")" = \
    ../init.d/commerDiagnoseServer
test "$(readlink "$VERIFY/etc/rc9.d/S30commerDiagnoseServer")" = \
    ../init.d/commerDiagnoseServer
for link in \
    etc/rc6.d/K27commerDiagnoseServer \
    etc/rc7.d/K27commerDiagnoseServer \
    etc/rc8.d/K27commerDiagnoseServer \
    etc/rc9.d/K88commerDiagnoseServer; do
    test "$(readlink "$VERIFY/$link")" = ../init.d/commerDiagnoseServer
done
grep -q 'zbmc-runtime.sh' "$VERIFY/etc/init.d/mountall.sh"
test -f "$VERIFY/zbmc-seed/conf/BMC1/wolfpass/IPMI.conf"
grep -q '^auto eth1$' "$VERIFY/zbmc-seed/conf/interfaces"
test -f "$VERIFY/usr/local/www/index.html"
test -f "$VERIFY/usr/local/www/source.min.js"
test -f "$VERIFY/usr/local/www/styles.min.css"
test ! -e "$VERIFY/usr/local/www/Java"

printf 'verified service CramFS: %s bytes\n' "$cramfs_size"
