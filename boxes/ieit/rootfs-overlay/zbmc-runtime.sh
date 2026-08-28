#!/bin/sh

mount_tmpfs() {
    target=$1
    options=$2

    grep -q " $target " /proc/mounts ||
        mount -t tmpfs -o "$options" tmpfs "$target"
}

echo "zbmc: establishing volatile BMC state"

mount_tmpfs /conf size=8m,mode=0755 || exit 1
mount_tmpfs /extlog size=4m,mode=0755 || exit 1
mount_tmpfs /usr/local/lmedia size=4m,mode=0755 || exit 1

cp -a /zbmc-seed/conf/. /conf/ || exit 1
echo "zbmc: preserved image-1 configuration seeded"
