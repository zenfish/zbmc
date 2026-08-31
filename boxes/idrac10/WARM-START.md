<!-- html2md:auto source=boxes/idrac10/WARM-START.html source-sha256=ac6fb5aa5a304b7a565116a792bf87e78a54091ebcc120ded7455ed4c4db39d5 body-sha256=4925881a85b76538a9ed32880fd262be7cf182691fd8515d6c89510e66be160f -->

zbmc / Dell NPCM845

# iDRAC10 warm start

Create a local QEMU checkpoint from a fully READY cold guest, then restore SSH, authenticated RMCP+ IPMI, Redfish, and the serial console in about 33 seconds on the measured Debby runs.

## Create the checkpoint

    sudo ./tools/zbmc idrac10 start
    # Wait for READY, then:
    sudo ./tools/zbmc idrac10 snapshot
    sudo ./tools/zbmc idrac10 down

`snapshot` refuses to run until IPMI answers. It atomically replaces the saved RAM state and frozen disk overlay. Stop the source immediately afterward because checkpoint creation hot-unplugs its non-migratable USB NIC.

## Restore and verify

    sudo ./tools/zbmc idrac10 start --warm
    ./tools/zbmc idrac10 status -v
    ./tools/zbmc idrac10 ipmi mc info

Ordinary `start` remains a cold boot. `--warm` is explicit and fails if either checkpoint artifact is absent.

## Checkpoint artifacts

    work/idrac10/ckpt/state.gz
    work/idrac10/ckpt/overlay-frozen.qcow2

The RAM stream and qcow2 overlay are a matched pair. They are local generated state, not bundled release artifacts. QEMU migration is version and topology specific; after changing the pinned QEMU, kernel, DTB, disk image, or launch topology, discard the old pair and create a new checkpoint from a successful cold run.

## Why warm uses one NIC

Cold boot uses QEMU `usb-net` for TCP services, but QEMU 11 reports that device as non-migratable. Snapshot creation removes it before migration. Warm restore keeps the two slirp backend instances required by the migration stream and forwards SSH, HTTPS, and UDP 623 through the migrated NPCM GMAC at `10.0.2.15`.

## Recovery

If restore fails, inspect `work/idrac10/ckpt/rqemu.log`. Return to the supported cold path with:

    sudo ./tools/zbmc idrac10 down
    sudo ./tools/zbmc idrac10 start

[Back to the iDRAC10 index](index.md)
