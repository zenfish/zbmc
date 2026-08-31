<!-- html2md:auto source=boxes/idrac10/index.html source-sha256=486d2a10d4b8e75a9420904d7b7d7eda4445070b713f46bbefa11558ed28fc8d body-sha256=b246d4c2aa6c487e34fd125c5bd309e0c09912bb0621a2f70f78e3ba3b4bbb1a -->

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
- [iDRAC9 versus iDRAC10 OEM command diff](idrac9-vs-idrac10-oem-diff.md) ([standalone copy](idrac9-vs-idrac10-oem-diff.standalone.html))
- [Raw IPMI command table](idrac10-ipmi-commands.md)
- [Dispatch-table extraction](idrac10-dispatch-tables.md)
- [Pilot OEM commands](pilot-oem-commands.md)
- [Historical state and resume notes](RESUME-STATE.md)
- [Historical live-iteration handoff](LIVE-ITERATE-HANDOFF.md)
