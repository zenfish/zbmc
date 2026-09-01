<!-- html2md:auto source=boxes/megarac-hpe/index.html source-sha256=f104221f91c92c4bc1c748017aeb1f968c89ce25790d0a35ab3d3b24f512c043 body-sha256=e0d7bcc038176a87ad09479024964ee1e734bd63b28adcb5184019a428130977 -->

# zbmc HPE XD670 MegaRAC

AMI MegaRAC SP-X on AST2600. The 2026-08-27 cold run reached retained IPMI in 8m07s total; its fourth attempt succeeded after three automatic `IPMIMain` crash rerolls. Redfish/Web-UI were unavailable and vendor SSH is not part of the accepted path.

## Current operation

    ./build.sh megarac-hpe
    sudo ./tools/zbmc megarac-hpe start
    ./tools/zbmc megarac-hpe status -v

## Documents

- [Virtual HPE XD670 BMC](README.md)
- [IPMI stack teardown](IPMI.md)
- [Historical emulation status](EMULATION-STATUS.md)
