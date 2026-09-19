<!-- html2md:auto source=boxes/megarac-hpe/index.html source-sha256=8f6afbda6346d75b6a67c246f8c7f3d6aaff7a2d4cad01a412004a11602494b3 body-sha256=5e49a3ab76568a80adc39efe30ed555b1c82229d7086046bec40bda448d8e123 -->

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

## Extracting the filesystem

Extract the packed root SquashFS and both 2 MiB JFFS2 configuration copies into `work/megarac-hpe/fs`:

    mkdir -p work/megarac-hpe/fs/rootfs work/megarac-hpe/fs/conf1 work/megarac-hpe/fs/conf2
    unsquashfs -d work/megarac-hpe/fs/rootfs work/megarac-hpe/rootfs.sqfs
    dd if=work/megarac-hpe/mtdflash.bin of=work/megarac-hpe/fs/conf1.jffs2 bs=1 skip=$((0x100000)) count=$((0x200000)) status=none
    dd if=work/megarac-hpe/mtdflash.bin of=work/megarac-hpe/fs/conf2.jffs2 bs=1 skip=$((0x300000)) count=$((0x200000)) status=none
    jefferson -f -d work/megarac-hpe/fs/conf1 work/megarac-hpe/fs/conf1.jffs2
    jefferson -f -d work/megarac-hpe/fs/conf2 work/megarac-hpe/fs/conf2.jffs2

The kernel, NOR bootloader, and firmware-info FMH remain packed.
