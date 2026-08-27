<!-- html2md:auto source=boxes/openbmc/index.html source-sha256=1d69ca5298f328ce81a13b23dc8b8c122303dbf4a18a312a87cff9cc3c882d12 body-sha256=39746491d7ec969e18f62eba04cec04dbbe3f4c5c0ec1fa6d96c6003e6fbd942 -->

# zbmc OpenBMC

Vanilla AST2600 OpenBMC control image. The accepted cold run reached ICMP, SSH, IPMI, Redfish, and Web-UI in 4m32s on the reference host.

## Current operation

    ./build.sh openbmc
    sudo ./tools/zbmc openbmc start
    ./tools/zbmc openbmc status -v

## Documents

- [Build information](BUILD-INFO.md)
- [IPMI and Redfish inventory](IPMI-REDFISH-INVENTORY.md)
