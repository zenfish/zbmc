<!-- html2md:auto source=boxes/irmc-fujitsu/index.html source-sha256=2a227bbb965f8e6e8f5a07d60e4bb63153e6f0db950a9e15a81aa2fce6ff3b1f body-sha256=9aeeb55f88be7f9d8422d29eab5905561aa4dcec046b375be059ff65ab7567f5 -->

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

The SD image format is vendor-specific. Enumerate it before extracting any partition into `work/irmc-fujitsu/fs`:

    mkdir -p work/irmc-fujitsu/fs
    guestfish --ro -a work/irmc-fujitsu/rootfs-sd.img
    # at the guestfish prompt: run; list-filesystems; mount /dev/sdaN /; tar-out / - ...

The initramfs is a separate packed CPIO archive:

    mkdir -p work/irmc-fujitsu/fs/initramfs
    gzip -dc work/irmc-fujitsu/initramfs.cpio.gz | (cd work/irmc-fujitsu/fs/initramfs && cpio -idm --no-absolute-filenames)
