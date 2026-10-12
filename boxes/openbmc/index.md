<!-- html2md:auto source=boxes/openbmc/index.html source-sha256=d195e1ffe324295a63aeddc32e529e41e845e72b5feeb3a6c54ea915a111e95c body-sha256=c7cb1cf647b1f1cd03010b088e4508b91057941b3f7b32c473fafd27382be693 -->

# zbmc OpenBMC

Vanilla AST2600 OpenBMC control image. The accepted cold run reached ICMP, SSH, IPMI, Redfish, and Web-UI in 4m32s on the reference host.

## Current operation

    ./build.sh openbmc
    sudo ./tools/zbmc openbmc start
    ./tools/zbmc openbmc status -v

## Documents

- [Build information](BUILD-INFO.md)
- [IPMI and Redfish inventory](IPMI-REDFISH-INVENTORY.md)

## OEM IPMI command surface

The pinned vanilla image has a closed zero-OEM result: five providers contain 81 standard/DCMI registrations and no vendor OEM registration. zipmi's canonical [baseline reference](https://github.com/zenfish/zipmi/blob/main/docs/openbmc-vanilla-command-reference.html) records the static census and 4,864 live Invalid Command replies. Other OpenBMC machine/provider combinations remain separate targets.

## Extracting the filesystem

The flash contains the read-only SquashFS root and a writable JFFS2 region. Extract both into `work/openbmc/fs`:

    mkdir -p work/openbmc/fs/rootfs work/openbmc/fs/rwfs
    unsquashfs -o 10485760 -d work/openbmc/fs/rootfs work/openbmc/flash.mtd
    dd if=work/openbmc/flash.mtd of=work/openbmc/fs/rwfs.jffs2 bs=1 skip=$((0x2a00000)) status=none
    jefferson -f -d work/openbmc/fs/rwfs work/openbmc/fs/rwfs.jffs2

The U-Boot and kernel regions remain packed in `flash.mtd`.
