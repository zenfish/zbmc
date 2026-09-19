<!-- html2md:auto source=boxes/megarac-hpe/index.html source-sha256=d5e2d7650e816d34ef72c7e2cebf1a820aada669542324cc474d23d04199e2c1 body-sha256=ae865012226118577da9405bec606ade86ae99ea50de2cdd1576ea956f680337 -->

# zbmc HPE XD670 MegaRAC

AMI MegaRAC SP-X on AST2600. The 2026-08-27 cold run reached retained IPMI in 8m07s total; its fourth attempt succeeded after three automatic `IPMIMain` crash rerolls. Redfish/Web-UI were unavailable and vendor SSH is not part of the accepted path.

## Current operation

    ./build.sh megarac-hpe
    sudo ./tools/zbmc megarac-hpe start
    ./tools/zbmc megarac-hpe status -v

## Copying files

The rebuilt cold service image provides a root Linux console. Confirm a shell prompt before sending commands; older warm images may still present a vendor login. Use the [shared guest-shell recipes](../../README.md#copy-from-a-guest-shell), or send a small command to the live console from the host:

    sudo ./tools/zbmc megarac-hpe console 'printf "hello\n" > /tmp/hello.txt; cat /tmp/hello.txt'

`zbmc megarac-hpe shell` starts a separate `init=/bin/sh` VM without the normal network/IPMI services; it does not attach to the running service VM.

If you specifically want the existing injected SSH service in an isolated lab, enable it both when starting a stopped box and when invoking SSH. The default path leaves it disabled:

    sudo env ZBMC_INSECURE_LAB_ACCESS=1 ./tools/zbmc megarac-hpe start
    ZBMC_INSECURE_LAB_ACCESS=1 ./tools/zbmc megarac-hpe ssh -T 'cat > /tmp/my-tool' < ./my-tool
    cksum ./my-tool
    ZBMC_INSECURE_LAB_ACCESS=1 ./tools/zbmc megarac-hpe ssh 'cksum /tmp/my-tool'

After matching checksums, use `chmod 755 /tmp/my-tool` and execute it through the same shell. Match the guest ABI: the packaged lab Dropbear uses ARM soft-float because this modeled CPU lacks the VFP support that a hard-float binary would require. Uploads to `/tmp` are disposable.

## Documents

- [Virtual HPE XD670 BMC](README.md)
- [IPMI stack teardown](IPMI.md)
- [Historical emulation status](EMULATION-STATUS.md)
