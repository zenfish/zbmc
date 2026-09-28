#!/usr/bin/env bash
# zbmc:turnkey - build a firmware-userspace iDRAC6 guest from an extracted 1.70 rootfs.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/idrac6}}"
SOURCE="${IDRAC6_ROOTFS:-$ROOT/firmware/idrac6-rootfs}"
KERNEL_URL=https://archive.debian.org/debian/dists/lenny/main/installer-armel/current/images/versatile/netboot/vmlinuz-2.6.26-2-versatile
INITRD_URL=https://archive.debian.org/debian/dists/lenny/main/installer-armel/current/images/versatile/netboot/initrd.gz
FULLFW_SHA256=67f17aa14eda9e5d96b96825b93536a228db031acda90122eb353fba56dd3465
KERNEL_SHA256=478d458edc67f8f38ed53ac44e706908daa59ccf85031933bfa838678fc2bd70
INITRD_SHA256=c9bb9a51734b95ce9ea231373a06c624a922f20e8823c7fa413bdd30d289a21b
PRIVATE_STORAGE_SHA256=fd349b3672122d5d8e89564ad8be6e03234199e95d8af602de046b36c20798ab

for tool in arm-linux-gnueabi-gcc cpio curl gzip sha256sum; do
  command -v "$tool" >/dev/null || { echo "iDRAC6 build needs $tool" >&2; exit 1; }
done
[ -f "$SOURCE/bin/fullfw" ] || {
  echo "missing extracted iDRAC6 1.70 rootfs: $SOURCE" >&2
  echo "set IDRAC6_ROOTFS=/path/to/WPCM450" >&2
  exit 1
}
[ "$(sha256sum "$SOURCE/bin/fullfw" | awk '{print $1}')" = "$FULLFW_SHA256" ] || {
  echo "iDRAC6 fullfw SHA-256 mismatch: $SOURCE/bin/fullfw" >&2
  exit 1
}
[ "$(sha256sum "$SOURCE/flash/data0/BMC_Data/NVRAM_PrivateStorage00.dat" | awk '{print $1}')" = "$PRIVATE_STORAGE_SHA256" ] || {
  echo "iDRAC6 captured private-storage SHA-256 mismatch" >&2
  exit 1
}

mkdir -p "$WD"
KERNEL="$WD/vmlinuz-2.6.26-2-versatile"
DEBIAN_INITRD="$WD/debian-versatile-initrd.gz"
[ -f "$KERNEL" ] || curl -fL "$KERNEL_URL" -o "$KERNEL"
[ -f "$DEBIAN_INITRD" ] || curl -fL "$INITRD_URL" -o "$DEBIAN_INITRD"
[ "$(sha256sum "$KERNEL" | awk '{print $1}')" = "$KERNEL_SHA256" ] || {
  echo "Debian versatile kernel SHA-256 mismatch" >&2; exit 1;
}
[ "$(sha256sum "$DEBIAN_INITRD" | awk '{print $1}')" = "$INITRD_SHA256" ] || {
  echo "Debian versatile initrd SHA-256 mismatch" >&2; exit 1;
}

STAGE=$(mktemp -d "$WD/.idrac6-build.XXXXXX")
cleanup() {
  case "$STAGE" in "$WD"/.idrac6-build.*) rm -rf -- "$STAGE";; esac
}
trap cleanup EXIT INT TERM HUP
GUEST="$STAGE/guest"
DEBIAN="$STAGE/debian"
mkdir -p "$GUEST" "$DEBIAN" "$GUEST/bin" "$GUEST/sbin"

printf '[1/4] copying the proven Dell userspace subset\n'
cp -a "$SOURCE/etc" "$SOURCE/flash" "$SOURCE/lib" "$GUEST/"
for file in busybox fullfw ipmiSystemCallAgent ipmi_gateway; do
  install -m 0755 "$SOURCE/bin/$file" "$GUEST/bin/$file"
done
install -m 0755 "$SOURCE/sbin/aim" "$GUEST/sbin/aim"
for link in "$SOURCE"/bin/*; do
  [ -L "$link" ] && cp -a "$link" "$GUEST/bin/"
done
for link in "$SOURCE"/sbin/*; do
  [ -L "$link" ] && cp -a "$link" "$GUEST/sbin/"
done
ln -s busybox "$GUEST/bin/sh"
install -m 0755 "$HERE/init" "$GUEST/init"

printf '[2/4] preserving the pinned LAN-enabled captured state\n'

printf '[3/4] adding the Debian VersatilePB NIC module and compatibility shim\n'
(cd "$DEBIAN" && gzip -dc "$DEBIAN_INITRD" | \
  cpio -idmu --quiet 'lib/modules/2.6.26-2-versatile/*')
cp -a "$DEBIAN/lib/modules/2.6.26-2-versatile" "$GUEST/lib/modules/"
arm-linux-gnueabi-gcc -march=armv5te -mfloat-abi=soft -shared -fPIC -nostdlib \
  -Wl,--hash-style=sysv,-soname,libidrac6-ioctl-shim.so,--version-script="$HERE/ioctl-shim.map" \
  "$HERE/ioctl-shim.c" -o "$GUEST/lib/libidrac6-ioctl-shim.so"

printf '[4/4] packing the initramfs and provenance\n'
(cd "$GUEST" && find . -print0 | cpio --null -o -H newc 2>/dev/null | gzip -9) \
  >"$STAGE/idrac6-initramfs.cpio.gz"
install -m 0644 "$STAGE/idrac6-initramfs.cpio.gz" "$WD/idrac6-initramfs.cpio.gz"
{
  printf 'scope=firmware-userspace emulation on QEMU VersatilePB; WPCM450 hardware is not modeled\n'
  printf 'source=%s\nfullfw_sha256=%s\nprivate_storage_sha256=%s\n' \
    "$SOURCE" "$FULLFW_SHA256" "$PRIVATE_STORAGE_SHA256"
  printf 'kernel_url=%s\nkernel_sha256=%s\n' "$KERNEL_URL" "$KERNEL_SHA256"
  printf 'initrd_url=%s\ninitrd_sha256=%s\n' "$INITRD_URL" "$INITRD_SHA256"
  sha256sum "$HERE/init" "$HERE/ioctl-shim.c" "$HERE/ioctl-shim.map" \
    "$WD/idrac6-initramfs.cpio.gz"
} >"$WD/build-provenance.txt"

echo "iDRAC6 firmware-userspace guest ready in $WD"
