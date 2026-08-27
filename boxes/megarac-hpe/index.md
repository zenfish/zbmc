<!-- html2md:auto source=boxes/megarac-hpe/index.html -->

# zbmc HPE XD670 MegaRAC

AMI MegaRAC SP-X on AST2600. The 2026-08-27 cold run reached retained IPMI in 8m07s after three automatic `IPMIMain` crash rerolls. Redfish/Web-UI were unavailable and vendor SSH is not part of the accepted path.

## Current operation

    ./build.sh megarac-hpe
    sudo ./tools/zbmc megarac-hpe start
    ./tools/zbmc megarac-hpe status -v

## Documents

- [Virtual HPE XD670 BMC](README.md)
- [IPMI stack teardown](IPMI.md)
- [Historical emulation status](EMULATION-STATUS.md)
