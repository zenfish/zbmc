<!-- html2md:auto source=boxes/irmc-fujitsu/index.html source-sha256=c924dc61a5f879b8df2560dda75acbea7a4af4151c1937a481807d81931ca414 body-sha256=ce43ba219fef9025f79617c733aca83ae5f1c9fe2a1ef4d5115d04f699e568f3 -->

# Fujitsu iRMC S6

RX2540 M7 firmware 02.63S / SDR 03.67 under QEMU's AST2600 model. The diagnostic runtime provides authenticated Linux SSH, RMCP+ IPMI, the preserved Fujitsu HTTPS Web UI, and Redfish. The derived two-flash topology lets the vendor Redfish DataModel initialize without the former `FwInfo2` panic.

## Operation

    ./build.sh irmc-fujitsu
    sudo ./tools/zbmc irmc-fujitsu start
    ./tools/zbmc irmc-fujitsu status -v
    ./tools/zbmc irmc-fujitsu ssh
    ./tools/zbmc irmc-fujitsu ipmi mc info

The cold build downloads five SHA-256-pinned artifacts from `https://git.trouble.org/zbmc/irmc-fujitsu/`. The guest uses the third emulated NIC; the first two slots are retained because the firmware binds its management interface by hardware index.

## Accepted boundary

- **Verified:** cold boot reaches SysV runlevel 3; `sysadmin/superuser` opens a root BusyBox Linux shell over SSH; authenticated RMCP+ IPMI answers on UDP/623; the Fujitsu HTTPS Web UI answers; and all 274 Redfish resources initialize before ServiceRoot returns HTTP 200.
- **Static management network:** before `IPMIMain` starts, the derived initramfs writes the vendor-owned LAN object `/conf/BMC1/lancfg0.ini` with `IPAddrSrc=1`, the requested IPv4 address, a `255.0.0.0` mask, the gateway, `IPv4_Enable=1`, and `IPv6_Enable=0`. `/conf/BMC1/LanIfccfg.ini` maps that zero-based LAN object to IPMI channel 2 on management `eth0`. The firmware then generates its own static `/conf/interfaces`; no host-side address repair loop remains.
- **IPMI cold-boot fix:** a recovered `/conf` partition defaults `AMI_DYNAMIC_LAN_IFC_SUPPORT`, management `eth0 Enabled`, and `eth0 Up_Status` to zero. The derived initramfs enables them before `IPMIMain` starts and removes the stale `/tmp/BMC1/IPMIConfig.dat` shadow cache. The pinned vendor inputs remain unchanged and all three attached QEMU drive mappings use snapshot mode.
- **Redfish recovery:** the original single-FMC topology made `helper.ko:fwinfo2_read` dereference a missing second `ractrends_mtd[]` bank at guest uptime 804.782 seconds. The derived runtime maps the same pinned 64 MiB flash image onto both FMC chip selects, concatenates those two snapshot-backed mappings for the AMI FMH parser, and mounts the original platform SquashFS before `switch_root`. A disposable VM completed all 274 DataModel entries, remained alive beyond the former panic boundary, returned HTTP 200 for ServiceRoot, and returned the expected authenticated `PasswordChangeRequired` response for Managers.
- **SSH recovery:** the diagnostic initramfs enables the vendor SSH service, normalizes the firmware-specific `sysadmin` passwd marker so PAM uses the preserved shadow hash, and bind-mounts the diagnostic shell over `defshell`'s `remman` target. Remote commands and interactive PTY sessions both reach the Linux shell; the pinned firmware and shadow hash remain unchanged.

The Debby acceptance run `20260924T060412Z-7a079809-e09d-44c5-8066-fddc2c54f560` reached READY in 8m52s with authenticated IPMI and the Web UI stable for the required interval. It returned Fujitsu manufacturer ID 10368 and product `0x0666` from `mc info`; five subsequent serialized HTTPS probes all returned HTTP 200 from `iRMC S6 Webserver`.

The final static-network/Redfish cold acceptance on 2026-09-24 retained `10.250.0.143/8` through the initial and delayed Fujitsu LAN reloads. A capture spanning the entire boot and both reloads watched UDP ports 67, 68, 546, and 547 and contained no packets. At guest uptime 1782.40 seconds, the vendor configuration still had `IPAddrSrc=1`, `IPv4_Enable=1`, and `IPv6_Enable=0`; neither DHCP client nor PID file existed. Redfish completed 274/274 resources and became responsive, the Web UI returned HTTP 200, and authenticated IPMI still identified Fujitsu manufacturer 10368 and product `0x0666`.

The Linux-SSH cold acceptance run `20260925T054554Z-e12565e1-dd69-45ee-9eb1-09df9e97ea7c` reached four-service READY in 25m30s. The functional SSH probe executed an exact marker through `sysadmin/superuser`; an interactive PTY identified UID/GID 0 and `/root`. The final verbose check passed 5/5 for ICMP, SSH, authenticated IPMI, authenticated Redfish, and the Web UI, with serial console available.

## IPMI internals

The cold-run timing, UDP/623 owner, RMCP+ dispatch path, named IPC queues, and per-command response sources are documented in the [IPMI listener and response-source trace](ipmi-path.md).

The [OEM IPMI and power-control map](oem-power-map.md) inventories all recovered Fujitsu dispatch tables and traces chassis power, reset, NMI, KCS, DCMI, watchdog, power-limit, Node Manager, PMBus, fan, and raw PECI paths to their current hardware or software boundary.

## Redfish internals

The [Redfish resource-provenance report](redfish-path.md) maps static resource definitions and `GenericMap.json` placeholders through the DataModel to configuration-store values, local IPMI, Redis, provider daemons, generated files, queues, and hardware-facing boundaries. It also explains the complete 274-entry initialization timeline and the misleading earlier “stuck at 162” status.

## Copying files

The default cold runtime enables the same diagnostic root Linux shell over SSH and serial. Use `sysadmin/superuser` for SSH, or attach to serial and press Enter:

    sudo ./tools/zbmc irmc-fujitsu console --nostderr

Follow the [shared host HTTP-server recipe](../../README.md#copy-from-a-guest-shell), using an address owned by the host on the directly attached `br-zbmc` network. For example, the Debby lab host is `http://10.0.0.24:8765/my-tool`. This box uses TAP/direct layer 2, not QEMU user networking or the `10.0.2.2` proxy address. Check the guest checksum before executing, use a compatible ARM32 binary, and expect `/tmp` to disappear on a cold boot. Small text/base64 payloads can also be entered at the serial shell. Ctrl-\] detaches.

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
