<!-- html2md:auto source=boxes/idrac10/index.html source-sha256=9dcfc892ddb73dfd2a229b798f4060f8cd98188a8d7e64ca78666c01e33e918d body-sha256=e71445bda9117894d0cc2636ef8d86f78015d7f2b76f6fa5520d7a93788b18b9 -->

# zbmc iDRAC10

NPCM845/AArch64 research box. The supported cold boot reached ICMP, SSH, retained IPMI, and the static Redfish ServiceRoot in 7m37s on the reference host. It has no vendor Web-UI.

## Current operation

    ./build.sh idrac10
    sudo ./tools/zbmc idrac10 start
    ./tools/zbmc idrac10 status -v

    # After a cold run reaches READY:
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
