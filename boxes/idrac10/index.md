<!-- html2md:auto source=boxes/idrac10/index.html source-sha256=22d92a36b40356e249ccc7fe5ebcc24f1c5533adade7c26725afb8bd6a41b7ff body-sha256=cff900d8d4e27cdf5d5e5be9f65bdb8c7290e32092ff65004c405fecc4cbc603 -->

# zbmc iDRAC10

NPCM845/AArch64 research box. The supported cold boot reached ICMP, SSH, retained IPMI, and the static Redfish ServiceRoot in 7m37s on the reference host. It has no vendor Web-UI.

## Current operation

    ./build.sh idrac10
    sudo ./tools/zbmc idrac10 start
    ./tools/zbmc idrac10 status -v

    # Optional: replace the downloaded checkpoint after a cold run reaches READY:
    sudo ./tools/zbmc idrac10 snapshot
    sudo ./tools/zbmc idrac10 down
    sudo ./tools/zbmc idrac10 start --warm

[Warm checkpoint creation, restore, compatibility, and recovery](WARM-START.md)

## Reference and analysis

- [Warm-start operator runbook](WARM-START.md)
- [OEM IPMI command reference](idrac10-oem-reference.md) ([standalone copy](idrac10-oem-reference.standalone.html))
- zipmi operator views: [command reference](https://github.com/zenfish/zipmi/blob/main/docs/idrac10-command-reference.html) · [compact firmware table](https://github.com/zenfish/zipmi/blob/main/docs/idrac10-command-table.html)
- [iDRAC9 versus iDRAC10 OEM command diff](idrac9-vs-idrac10-oem-diff.md) ([standalone copy](idrac9-vs-idrac10-oem-diff.standalone.html))
- [Raw IPMI command table](idrac10-ipmi-commands.md)
- [Dispatch-table extraction](idrac10-dispatch-tables.md)
- [Pilot OEM commands](pilot-oem-commands.md)
- [Historical state and resume notes](RESUME-STATE.md)
- [Historical live-iteration handoff](LIVE-ITERATE-HANDOFF.md)

## Extracting the filesystem

The root filesystem is the SquashFS payload in the built SD image. Extract it under `work/idrac10/fs`:

    mkdir -p work/idrac10/fs
    unsquashfs -d work/idrac10/fs work/idrac10/img/sd.img

`sd.img` remains the boot artifact; the extracted tree is a copy for inspection or a separately rebuilt image.
