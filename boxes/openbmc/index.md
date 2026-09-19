<!-- html2md:auto source=boxes/openbmc/index.html source-sha256=da236f0d5a12a500f94084987f3a060d3b2e69e37900d42bfb4b80092dcffb44 body-sha256=a1600d1ae43c503e4efd965639b41cc29c292dd4f57f9185ad9344ad55eca1e9 -->

# zbmc OpenBMC

Vanilla AST2600 OpenBMC control image. The accepted cold run reached ICMP, SSH, IPMI, Redfish, and Web-UI in 4m32s on the reference host.

## Current operation

    ./build.sh openbmc
    sudo ./tools/zbmc openbmc start
    ./tools/zbmc openbmc status -v

## Documents

- [Build information](BUILD-INFO.md)
- [IPMI and Redfish inventory](IPMI-REDFISH-INVENTORY.md)

## Extracting the filesystem

The flash contains the read-only SquashFS root and a writable JFFS2 region. Extract both into `work/openbmc/fs`:

    mkdir -p work/openbmc/fs/rootfs work/openbmc/fs/rwfs
    unsquashfs -o 10485760 -d work/openbmc/fs/rootfs work/openbmc/flash.mtd
    dd if=work/openbmc/flash.mtd of=work/openbmc/fs/rwfs.jffs2 bs=1 skip=$((0x2a00000)) status=none
    jefferson -f -d work/openbmc/fs/rwfs work/openbmc/fs/rwfs.jffs2

The U-Boot and kernel regions remain packed in `flash.mtd`.
