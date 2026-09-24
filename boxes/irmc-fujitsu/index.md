<!-- html2md:auto source=boxes/irmc-fujitsu/index.html source-sha256=44e6ada5ba72f8fdbce1e60d78a03c5e2d228135deca3842f2130452d8b751a6 body-sha256=62e42c79eb12245db9e8c6a5bebc6154ec0a1b5e513ba257dcafba25e63b95b2 -->

# Fujitsu iRMC S6

RX2540 M7 firmware 02.63S / SDR 03.67 under QEMU's AST2600 model. Authenticated RMCP+ IPMI and the preserved Fujitsu HTTPS Web UI both answer. Redfish is intentionally disabled.

## Operation

    ./build.sh irmc-fujitsu
    sudo ./tools/zbmc irmc-fujitsu start
    ./tools/zbmc irmc-fujitsu status -v
    ./tools/zbmc irmc-fujitsu ipmi mc info

The cold build downloads five SHA-256-pinned artifacts from `https://git.trouble.org/zbmc/irmc-fujitsu/`. The guest uses the third emulated NIC; the first two slots are retained because the firmware binds its management interface by hardware index.

## Accepted boundary

- **Verified:** cold boot reaches SysV runlevel 3, authenticated RMCP+ IPMI answers on UDP/623, and the preserved Fujitsu HTTPS Web UI answers.
- **IPMI cold-boot fix:** a recovered `/conf` partition defaults `AMI_DYNAMIC_LAN_IFC_SUPPORT`, management `eth0 Enabled`, and `eth0 Up_Status` to zero. The derived initramfs enables them before `IPMIMain` starts and removes the stale `/tmp/BMC1/IPMIConfig.dat` shadow cache. The pinned vendor inputs remain unchanged and both QEMU drives use snapshot mode.
- **Known broken:** starting `FTS_RedfishService` causes a reproducible `helper.ko` `fwinfo2` NULL dereference with this reduced QEMU topology, so the boot disables it.
- **Not accepted:** SSH reaches the vendor-gated `defshell`, not a Unix command shell.

The Debby acceptance run `20260924T060412Z-7a079809-e09d-44c5-8066-fddc2c54f560` reached READY in 8m52s with authenticated IPMI and the Web UI stable for the required interval. It returned Fujitsu manufacturer ID 10368 and product `0x0666` from `mc info`; five subsequent serialized HTTPS probes all returned HTTP 200 from `iRMC S6 Webserver`.

## IPMI internals

The cold-run timing, UDP/623 owner, RMCP+ dispatch path, named IPC queues, and per-command response sources are documented in the [IPMI listener and response-source trace](ipmi-path.md).

The [OEM IPMI and power-control map](oem-power-map.md) inventories all recovered Fujitsu dispatch tables and traces chassis power, reset, NMI, KCS, DCMI, watchdog, power-limit, Node Manager, PMBus, fan, and raw PECI paths to their current hardware or software boundary.

## Copying files

The default cold runtime enables a diagnostic root Linux shell on serial; SSH still reaches the vendor-gated `defshell`. On the host, attach after startup and press Enter for the shell:

    sudo ./tools/zbmc irmc-fujitsu console --nostderr

Follow the [shared host HTTP-server recipe](../../README.md#copy-from-a-guest-shell), but use `http://192.168.2.2:8765/my-tool` in the guest's `wget` command. This box's QEMU user network is `192.168.2.0/24`; the generic `10.0.2.2` address does not apply. Check the guest checksum before executing, use a compatible ARM32 binary, and expect `/tmp` to disappear on a cold boot. Small text/base64 payloads can also be entered at the serial shell. Ctrl-\] detaches.

## Cold artifact set

    e139d58349922e59b763d5d1824e8fb60865524c206dda3b975769d5c4641df3  kernel.bin
    877bcd44fd590e800035ac221d386fc6908cb20ddcc575708ad1558bec758592  system-patched.dtb
    aed0ce8eb706180b21e798acad707d26f2e7a9e5d8d6f5933ec3ad7f2f13ad14  initramfs.cpio.gz
    e029ad09372a37c400b30446701440f905a855042174d3222e542261acbb152c  flash64.img
    4b9cea861e4c71ce1d0c71d1b8692705e02305eda7eeba4cd322946ea9524d78  rootfs-sd.img

## Extracting the filesystem

The SD image format is vendor-specific. Use the repository extractor to enumerate every mountable partition and export each one read-only under `work/irmc-fujitsu/fs`. It does not modify the source image:

    ./tools/extract-image-filesystems work/irmc-fujitsu/rootfs-sd.img work/irmc-fujitsu/fs

The command requires `guestfish` from `libguestfs-tools`. It reports each device and filesystem type as it is extracted. Unknown, swap, signed boot, and partition-table regions remain packed because they are not filesystems.
