#!/usr/bin/env bash
# zbmc:turnkey - reconstruct the IEIT/Inspur NF5468M6 service image from its original 64 MiB IMA.
set -euo pipefail
PATH=/usr/sbin:/sbin:$PATH
export PATH

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/ieit}}"
SOURCE="$ROOT/firmware/BMC_Whitley_7.26.05_Standard_IEY_20260707.ima"
SOURCE_SHA256=b7915aa4be2661d47d78cca6265dc11d8d06c23cc199e0ff80a2adc3ccd7c7d1
RAMDISK_OFFSET=$((0x18b0000))
RAMDISK_SIZE=$((0x1c4e040))
KERNEL_OFFSET=$((0x3500040))
KERNEL_SIZE=$((0x2a85d8))
WEB_OFFSET=$((0x37c0000))
WEB_SIZE=7720960
CONF_OFFSET=$((0x0b0000))
CONF_SIZE=$((0x200000))
ENV_OFFSET=$((0x2da8e))
ENV_SIZE=188
RAMDISK_LIMIT=$((35840 * 1024))

for tool in dd fakeroot fsck.cramfs jefferson mkfs.cramfs mkimage sha256sum tar; do
    command -v "$tool" >/dev/null 2>&1 || {
        echo "IEIT build needs $tool (install util-linux-extra, fakeroot, u-boot-tools; pipx install jefferson)" >&2
        exit 1
    }
done
[ -f "$SOURCE" ] || bash "$ROOT/firmware/download-fw.sh" ieit
[ -f "$SOURCE" ] || { echo "missing IEIT firmware: $SOURCE" >&2; exit 1; }
[ "$(sha256sum "$SOURCE" | awk '{print $1}')" = "$SOURCE_SHA256" ] || {
    echo "IEIT source firmware SHA-256 mismatch: $SOURCE" >&2
    exit 1
}

mkdir -p "$WD"
STAGE=$(mktemp -d "$WD/.ieit-build.XXXXXX")
cleanup() {
    case "$STAGE" in "$WD"/.ieit-build.*) rm -rf -- "$STAGE";; esac
}
trap cleanup EXIT INT TERM HUP

printf '[1/6] carving preserved firmware regions\n'
dd if="$SOURCE" of="$STAGE/ramdisk.uimage" bs=64 \
    skip="$((RAMDISK_OFFSET / 64))" count="$((RAMDISK_SIZE / 64))" status=none
dd if="$SOURCE" of="$STAGE/kernel.uimage" bs=8 \
    skip="$((KERNEL_OFFSET / 8))" count="$((KERNEL_SIZE / 8))" status=none
dd if="$SOURCE" of="$STAGE/web-ui.cramfs" bs=64 \
    skip="$((WEB_OFFSET / 64))" count="$((WEB_SIZE / 64))" status=none
dd if="$SOURCE" of="$STAGE/image1-conf.jffs2" bs=65536 \
    skip="$((CONF_OFFSET / 65536))" count="$((CONF_SIZE / 65536))" status=none
dd if="$STAGE/ramdisk.uimage" of="$STAGE/original-rootfs.cramfs" bs=64 skip=1 status=none

printf '[2/6] extracting preserved image-1 config and vendor Web-UI\n'
jefferson -f -d "$STAGE/image1-conf" "$STAGE/image1-conf.jffs2" >/dev/null
fakeroot -- fsck.cramfs --extract="$STAGE/web-ui" "$STAGE/web-ui.cramfs"
test -f "$STAGE/image1-conf/BMC1/wolfpass/IPMI.conf"
test -f "$STAGE/web-ui/index.html"

printf '[3/6] rebuilding metadata-preserving service CramFS\n'
fakeroot -- bash "$HERE/build-rootfs.sh" \
    "$STAGE/original-rootfs.cramfs" "$STAGE/image1-conf" "$STAGE/web-ui" \
    "$STAGE/service" "$STAGE/service-rootfs.cramfs"

printf '[4/6] wrapping rebuilt CramFS as a deterministic U-Boot ramdisk\n'
SOURCE_DATE_EPOCH=1783391527 mkimage \
    -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n '' \
    -d "$STAGE/service-rootfs.cramfs" "$STAGE/service-ramdisk.uimage" >/dev/null
[ "$(stat -c %s "$STAGE/service-rootfs.cramfs")" -le "$RAMDISK_LIMIT" ]

printf '[5/6] patching only the disposable U-Boot default environment\n'
tr '\n' '\0' <"$HERE/default-env.txt" >"$STAGE/default-env.bin"
printf '\0' >>"$STAGE/default-env.bin"
env_size=$(stat -c %s "$STAGE/default-env.bin")
[ "$env_size" -le "$ENV_SIZE" ] || { echo "IEIT default environment exceeds $ENV_SIZE bytes" >&2; exit 1; }
dd if=/dev/zero bs=1 count="$((ENV_SIZE - env_size))" status=none >>"$STAGE/default-env.bin"
cp "$SOURCE" "$STAGE/ieit-runtime.ima"
dd if="$STAGE/default-env.bin" of="$STAGE/ieit-runtime.ima" bs=1 \
    seek="$ENV_OFFSET" conv=notrunc status=none
cmp -s "$STAGE/default-env.bin" \
    <(dd if="$STAGE/ieit-runtime.ima" bs=1 skip="$ENV_OFFSET" count="$ENV_SIZE" status=none)

printf '[6/6] publishing verified runtime artifacts\n'
install -m 0644 "$STAGE/ieit-runtime.ima" "$WD/ieit-runtime.ima"
install -m 0644 "$STAGE/kernel.uimage" "$WD/kernel.uimage"
install -m 0644 "$STAGE/service-rootfs.cramfs" "$WD/service-rootfs.cramfs"
install -m 0644 "$STAGE/service-ramdisk.uimage" "$WD/service-ramdisk.uimage"
{
    printf 'source=%s\nsource_sha256=%s\n' "$SOURCE" "$SOURCE_SHA256"
    printf 'config=offset=0x%x size=0x%x\n' "$CONF_OFFSET" "$CONF_SIZE"
    printf 'ramdisk=offset=0x%x size=0x%x\n' "$RAMDISK_OFFSET" "$RAMDISK_SIZE"
    printf 'kernel=offset=0x%x size=0x%x\n' "$KERNEL_OFFSET" "$KERNEL_SIZE"
    printf 'web_ui=offset=0x%x size=%s\n' "$WEB_OFFSET" "$WEB_SIZE"
    printf 'environment=offset=0x%x size=%s\n' "$ENV_OFFSET" "$ENV_SIZE"
    printf 'web_excluded=Java (legacy Java remote-console clients; HTML5 UI retained)\n'
    sha256sum "$HERE/default-env.txt" "$HERE/rootfs-overlay/"* \
        "$WD/ieit-runtime.ima" "$WD/kernel.uimage" \
        "$WD/service-rootfs.cramfs" "$WD/service-ramdisk.uimage"
} >"$WD/build-provenance.txt"

echo "IEIT runtime ready in $WD"
