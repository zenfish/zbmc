<!-- html2md:auto source=boxes/openbmc/index.html source-sha256=4184e7b73c142d61c9311d0480b776e45e4938e0644a58778e125f724bf4ef4b body-sha256=c84c4613af8ce172e0564203b9db177388845fe910057859598ca5e044d22a30 -->

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

The build artifact is a complete flash image. Extract its root SquashFS at offset `0xa00000` into `work/openbmc/fs`:

    mkdir -p work/openbmc/fs
    unsquashfs -o 10485760 -d work/openbmc/fs work/openbmc/flash.mtd

The U-Boot, kernel, and other flash regions remain packed in `flash.mtd`.
