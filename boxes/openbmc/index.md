<!-- html2md:auto source=boxes/openbmc/index.html -->

# zbmc OpenBMC

Vanilla AST2600 OpenBMC control image. The accepted cold run reached ICMP, SSH, IPMI, Redfish, and Web-UI in 4m32s on the reference host.

## Current operation

    ./build.sh openbmc
    sudo ./tools/zbmc openbmc start
    ./tools/zbmc openbmc status -v

## Documents

- [Build information](BUILD-INFO.md)
- [IPMI and Redfish inventory](IPMI-REDFISH-INVENTORY.md)
