<!-- html2md:auto source=boxes/idrac10/WARM-START.html source-sha256=11eaaad99d670e7adc4c9684b7d183288061bfc13531e40aa42870ab361fe1af body-sha256=91154471106356f807ba80a4d904a239814c06dc09d251060e2673f955f09b63 -->

zbmc / Dell NPCM845

# iDRAC10 warm start

The management GMAC now owns the advertised address directly through TAP. Create a topology-matched checkpoint from a READY cold guest to enable warm restore.

## Install or replace the checkpoint

    sudo ./tools/zbmc idrac10 start
    # Wait for READY, then:
    sudo ./tools/zbmc idrac10 snapshot
    sudo ./tools/zbmc idrac10 down

`./build.sh idrac10` installs cold artifacts only. `snapshot` refuses to run until IPMI answers and writes a TAP topology marker with the matched pair. Stop the source immediately afterward because checkpoint creation hot-unplugs its non-migratable USB NIC.

## Restore and verify

    sudo ./tools/zbmc idrac10 start --warm
    ./tools/zbmc idrac10 status -v
    ./tools/zbmc idrac10 ipmi mc info

Ordinary `start` remains a cold boot. `--warm` is explicit and fails unless the state, overlay, and TAP topology marker are present and matched.

## Checkpoint artifacts

    work/idrac10/ckpt/state.gz
    work/idrac10/ckpt/overlay-frozen.qcow2
    work/idrac10/ckpt/network-mode

The RAM stream, qcow2 overlay, and network marker are one matched set. The former published checkpoint contains SLiRP migration state and is deliberately rejected. QEMU migration is version and topology specific; after changing QEMU, kernel, DTB, disk image, TAP name, MAC, address, or launch topology, create a newly verified set.

## Management versus bootstrap networking

The NPCM GMAC is TAP-backed and owns the advertised address; SSH, HTTPS, and UDP 623 use it directly without host forwarding. A separate QEMU `usb-net` remains on isolated SLiRP `10.0.3.0/24` only to fetch bootstrap payloads from the host. It does not advertise or proxy the management address. Snapshot creation removes the non-migratable USB device while retaining the internal backend required by the migration stream.

## Recovery

If restore fails, inspect `work/idrac10/ckpt/rqemu.log`. Return to the supported cold path with:

    sudo ./tools/zbmc idrac10 down
    sudo ./tools/zbmc idrac10 start

[Back to the iDRAC10 index](index.md)
