<!-- html2md:auto source=boxes/idrac10/WARM-START.html source-sha256=a313e460281b0b2604acb1edf237d8286ca37f2128718e998910c4455ad8c5fb body-sha256=d6ebf5c3af323effba89c1c729dae442c7f31573bf9b90430c79a31f4c9bb80e -->

zbmc / Dell NPCM845

# iDRAC10 warm start

The standard build downloads a matched warm bundle from git.trouble.org. Restore SSH, authenticated RMCP+ IPMI, Redfish, and the serial console in about 33 seconds on the measured Debby runs, or replace the bundle with a checkpoint from your own READY cold guest.

## Install or replace the checkpoint

    sudo ./tools/zbmc idrac10 start
    # Wait for READY, then:
    sudo ./tools/zbmc idrac10 snapshot
    sudo ./tools/zbmc idrac10 down

`./build.sh idrac10` installs the published checkpoint automatically. Use the commands above only to replace it. `snapshot` refuses to run until IPMI answers and atomically replaces the matched pair. Stop the source immediately afterward because checkpoint creation hot-unplugs its non-migratable USB NIC.

## Restore and verify

    sudo ./tools/zbmc idrac10 start --warm
    ./tools/zbmc idrac10 status -v
    ./tools/zbmc idrac10 ipmi mc info

Ordinary `start` remains a cold boot. `--warm` is explicit and fails if either checkpoint artifact is absent.

## Checkpoint artifacts

    work/idrac10/ckpt/state.gz
    work/idrac10/ckpt/overlay-frozen.qcow2

The RAM stream and qcow2 overlay are a matched pair published under `https://git.trouble.org/zbmc/idrac10/warm-20260831/` with pinned SHA-256 values in `build.sh`. QEMU migration is version and topology specific; after changing the pinned QEMU, kernel, DTB, disk image, or launch topology, create and publish a newly verified pair.

## Why warm uses one NIC

Cold boot uses QEMU `usb-net` for TCP services, but QEMU 11 reports that device as non-migratable. Snapshot creation removes it before migration. Warm restore keeps the two slirp backend instances required by the migration stream and forwards SSH, HTTPS, and UDP 623 through the migrated NPCM GMAC at `10.0.2.15`.

## Recovery

If restore fails, inspect `work/idrac10/ckpt/rqemu.log`. Return to the supported cold path with:

    sudo ./tools/zbmc idrac10 down
    sudo ./tools/zbmc idrac10 start

[Back to the iDRAC10 index](index.md)
