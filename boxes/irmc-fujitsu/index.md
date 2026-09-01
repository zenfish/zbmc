<!-- html2md:auto source=boxes/irmc-fujitsu/index.html source-sha256=b40f19e170a3377b84226380d4bc2868b2aea89c491b4d9043d82304818f43b7 body-sha256=161a36be7b9cedbb4a57c63046179be2af9a951e6f8aa190a06de998939ae835 -->

# Fujitsu iRMC S6

RX2540 M7 firmware 02.63S / SDR 03.67 under QEMU's AST2600 model. The preserved vendor Web UI works. RMCP+ IPMI starts but does not answer, and Redfish is intentionally disabled.

## Operation

    ./build.sh irmc-fujitsu
    sudo ./tools/zbmc irmc-fujitsu start
    ./tools/zbmc irmc-fujitsu status -v
    ./tools/zbmc irmc-fujitsu ipmi mc info

The cold build downloads five SHA-256-pinned artifacts from `https://git.trouble.org/zbmc/irmc-fujitsu/`. The guest uses the third emulated NIC; the first two slots are retained because the firmware binds its management interface by hardware index.

## Accepted boundary

- **Verified:** cold boot reaches SysV runlevel 3 and the preserved Fujitsu HTTPS Web UI answers.
- **Unknown:** `IPMIMain` launches, but UDP/623 requests receive no RMCP+ response.
- **Known broken:** starting `FTS_RedfishService` causes a reproducible `helper.ko` `fwinfo2` NULL dereference with this reduced QEMU topology, so the boot disables it.
- **Not accepted:** SSH reaches the vendor-gated `defshell`, not a Unix command shell.

The Debby acceptance run `20260901T054304Z-62f6d82f-9aa2-4f98-8e5e-98a425cd2667` reached HTTP 200 at 9m22s and passed the stability hold at 9m40s.

## Cold artifact set

    e139d58349922e59b763d5d1824e8fb60865524c206dda3b975769d5c4641df3  kernel.bin
    877bcd44fd590e800035ac221d386fc6908cb20ddcc575708ad1558bec758592  system-patched.dtb
    aed0ce8eb706180b21e798acad707d26f2e7a9e5d8d6f5933ec3ad7f2f13ad14  initramfs.cpio.gz
    e029ad09372a37c400b30446701440f905a855042174d3222e542261acbb152c  flash64.img
    4b9cea861e4c71ce1d0c71d1b8692705e02305eda7eeba4cd322946ea9524d78  rootfs-sd.img
