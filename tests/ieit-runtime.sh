#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
box="$repo/boxes/ieit"

for script in "$box/build.sh" "$box/build-rootfs.sh" "$box/boot.sh" \
              "$box/rootfs-overlay/commerDiagnoseServer-wrapper.sh"; do
    bash -n "$script"
done

grep -Fxq 'ZBMC_QEMU_MAJOR=11' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_VERSION=11.0.0' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=ast2500-evb' "$box/zbmc.box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES="ssh ipmi redfish webui"' "$box/zbmc.box"
grep -Fxq 'ZBMC_L2_REQUIRED=0' "$box/zbmc.box"
grep -Fxq "ZBMC_SSH_NOTE='authenticated SMASH CLI; not a Unix shell'" "$box/zbmc.box"
grep -Fxq "ZBMC_READY_GREP='Starting lighttpd'" "$box/zbmc.box"
grep -Fxq 'IPMI_OPTS="-C 17 -I lanplus"' "$box/zbmc.box"
grep -Fq -- '-C 17 -I lanplus -t "$IPMI_T"' "$box/zbmc.box"
grep -Fq 'grep -q "${ZBMC_READY_GREP}" "${_zr_console_log:-/dev/null}"' \
    "$repo/tools/zbmc-runlib"

grep -Fq 'SOURCE_SHA256=b7915aa4be2661d47d78cca6265dc11d8d06c23cc199e0ff80a2adc3ccd7c7d1' "$box/build.sh"
grep -Fq 'CONF_OFFSET=$((0x0b0000))' "$box/build.sh"
grep -Fq 'RAMDISK_OFFSET=$((0x18b0000))' "$box/build.sh"
grep -Fq 'KERNEL_OFFSET=$((0x3500040))' "$box/build.sh"
grep -Fq 'WEB_OFFSET=$((0x37c0000))' "$box/build.sh"
grep -Fq -- "--exclude './Java'" "$box/build-rootfs.sh"
grep -Fq 'mount_tmpfs /conf' "$box/rootfs-overlay/zbmc-runtime.sh"
grep -Fq 'auto eth1' "$box/rootfs-overlay/interfaces"
grep -Fq 'board EEPROM and host complex are not modeled' \
    "$box/rootfs-overlay/commerDiagnoseServer-wrapper.sh"
grep -Fq 'commerDiagnoseServer.vendor.sh' "$box/build-rootfs.sh"
diagnose_start=$(
    "$box/rootfs-overlay/commerDiagnoseServer-wrapper.sh" start
)
test "$diagnose_start" = \
    'zbmc: CommerDiagnose disabled (board EEPROM and host complex are not modeled)'
test -z "$("$box/rootfs-overlay/commerDiagnoseServer-wrapper.sh" stop)"

tmp=$(mktemp -d "${TMPDIR:-/tmp}/ieit-runtime.XXXXXX")
trap 'rm -rf "$tmp"' EXIT
fixture="$tmp/original-rootfs"
conf="$tmp/conf"
web="$tmp/web"
mock_bin="$tmp/bin"
packed="$tmp/packed-rootfs"
stage="$tmp/stage"
mkdir -p "$fixture"/{bin,sbin,etc/init.d,etc/rcS.d,etc/rc6.d,etc/rc7.d,etc/rc8.d,etc/rc9.d,usr/local/bin,usr/local/sbin,usr/local/www} \
    "$conf/BMC1/wolfpass" "$web/Java" "$mock_bin" "$packed"

for file in bin/sh sbin/init etc/init.d/mountall.sh etc/init.d/ncsicfg.sh \
            etc/init.d/phycfg.sh etc/init.d/commerDiagnoseServer; do
    printf '#!/bin/sh\nexit 0\n' >"$fixture/$file"
    chmod 0755 "$fixture/$file"
done
printf 'vendor diagnostic\n' >"$fixture/etc/init.d/commerDiagnoseServer"
chmod 0755 "$fixture/etc/init.d/commerDiagnoseServer"
ln -s ../init.d/mountall.sh "$fixture/etc/rcS.d/S06mountall.sh"
ln -s ../init.d/ncsicfg.sh "$fixture/etc/rcS.d/S38ncsicfg.sh"
ln -s ../init.d/phycfg.sh "$fixture/etc/rcS.d/S40phycfg.sh"
ln -s ../init.d/commerDiagnoseServer "$fixture/etc/rcS.d/S46commerDiagnoseServer"
ln -s ../init.d/commerDiagnoseServer "$fixture/etc/rc9.d/S30commerDiagnoseServer"
ln -s ../init.d/commerDiagnoseServer "$fixture/etc/rc6.d/K27commerDiagnoseServer"
ln -s ../init.d/commerDiagnoseServer "$fixture/etc/rc7.d/K27commerDiagnoseServer"
ln -s ../init.d/commerDiagnoseServer "$fixture/etc/rc8.d/K27commerDiagnoseServer"
ln -s ../init.d/commerDiagnoseServer "$fixture/etc/rc9.d/K88commerDiagnoseServer"
printf 'ipmi service\n' >"$fixture/usr/local/bin/IPMIMain"
printf 'web service\n' >"$fixture/usr/local/sbin/lighttpd"
printf 'ipmi config\n' >"$conf/BMC1/wolfpass/IPMI.conf"
printf 'index\n' >"$web/index.html"
printf 'javascript\n' >"$web/source.min.js"
printf 'css\n' >"$web/styles.min.css"
printf 'excluded\n' >"$web/Java/legacy-client.jar"
touch "$tmp/original.cramfs"

cat >"$mock_bin/fsck.cramfs" <<'EOF'
#!/bin/sh
set -eu
dest=${1#--extract=}
image=$2
rm -rf "$dest"
mkdir -p "$dest"
case "$image" in
    "$MOCK_ORIGINAL") cp -a "$MOCK_FIXTURE/." "$dest/" ;;
    "$MOCK_OUTPUT") cp -a "$MOCK_PACKED/." "$dest/" ;;
    *) exit 1 ;;
esac
EOF
cat >"$mock_bin/mkfs.cramfs" <<'EOF'
#!/bin/sh
set -eu
rm -rf "$MOCK_PACKED"
mkdir -p "$MOCK_PACKED"
cp -a "$1/." "$MOCK_PACKED/"
printf x >"$2"
EOF
cat >"$mock_bin/stat" <<'EOF'
#!/bin/sh
set -eu
if [ "$1" = -c ] && [ "$2" = %s ]; then
    wc -c <"$3" | tr -d ' '
else
    exec /usr/bin/stat "$@"
fi
EOF
chmod 0755 "$mock_bin"/*

MOCK_ORIGINAL="$tmp/original.cramfs" \
MOCK_OUTPUT="$tmp/service-rootfs.cramfs" \
MOCK_FIXTURE="$fixture" \
MOCK_PACKED="$packed" \
PATH="$mock_bin:$PATH" \
    "$box/build-rootfs.sh" "$tmp/original.cramfs" "$conf" "$web" \
        "$stage" "$tmp/service-rootfs.cramfs" >/dev/null

result="$stage/verify"
grep -Fxq 'vendor diagnostic' \
    "$result/etc/init.d/commerDiagnoseServer.vendor.sh"
grep -Fq 'CommerDiagnose disabled' \
    "$result/etc/init.d/commerDiagnoseServer"
test "$(readlink "$result/etc/rcS.d/S46commerDiagnoseServer")" = \
    ../init.d/commerDiagnoseServer
test "$(readlink "$result/etc/rc9.d/S30commerDiagnoseServer")" = \
    ../init.d/commerDiagnoseServer
for link in \
    etc/rc6.d/K27commerDiagnoseServer \
    etc/rc7.d/K27commerDiagnoseServer \
    etc/rc8.d/K27commerDiagnoseServer \
    etc/rc9.d/K88commerDiagnoseServer; do
    test "$(readlink "$result/$link")" = ../init.d/commerDiagnoseServer
done
grep -Fxq 'ipmi service' "$result/usr/local/bin/IPMIMain"
grep -Fxq 'web service' "$result/usr/local/sbin/lighttpd"
test ! -e "$result/usr/local/www/Java"

grep -Fq -- '-M ast2500-evb,fmc-model=mx66l51235f,bmc-console=uart5' "$box/boot.sh"
grep -Fq -- 'loader,file=$WD/kernel.uimage,addr=0x83000000' "$box/boot.sh"
grep -Fq -- 'loader,file=$WD/service-ramdisk.uimage,addr=0x85000000' "$box/boot.sh"
grep -Fq 'hostfwd=udp:$IP:$IPMI_PORT-:623' "$box/boot.sh"

grep -Eq '^ieit[[:space:]]+10\.0\.6\.67$' "$repo/zhosts.txt"
grep -Fq '"ieit|BMC_Whitley_7.26.05_Standard_IEY_20260707.ima|' "$repo/firmware/download-fw.sh"
grep -Fq 'ast2500-evb' "$repo/qemu/recipes/qemu-11-arm.sh"
