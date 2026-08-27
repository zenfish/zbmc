<!-- html2md:auto source=boxes/idrac10/index.html source-sha256=59efe11038025c84f07c33366a89d203225fbfbb966f0770e10964c77e38bcc9 body-sha256=f6bd154da78cef43c76cada1956cf4157fc832715366286f49e2f11c5e54eadd -->

# zbmc iDRAC10

NPCM845/AArch64 research box. The supported cold boot reached ICMP, SSH, retained IPMI, and the static Redfish ServiceRoot in 7m37s on the reference host. It has no vendor Web-UI.

## Current operation

    ./build.sh idrac10
    sudo ./tools/zbmc idrac10 start
    ./tools/zbmc idrac10 status -v

## Reference and analysis

- [OEM IPMI command reference](idrac10-oem-reference.md) ([standalone copy](idrac10-oem-reference.standalone.html))
- [iDRAC9 versus iDRAC10 OEM command diff](idrac9-vs-idrac10-oem-diff.md) ([standalone copy](idrac9-vs-idrac10-oem-diff.standalone.html))
- [Raw IPMI command table](idrac10-ipmi-commands.md)
- [Dispatch-table extraction](idrac10-dispatch-tables.md)
- [Pilot OEM commands](pilot-oem-commands.md)
- [Historical state and resume notes](RESUME-STATE.md)
- [Historical live-iteration handoff](LIVE-ITERATE-HANDOFF.md)
