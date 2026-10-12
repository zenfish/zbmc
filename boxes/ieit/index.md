<!-- html2md:auto source=boxes/ieit/index.html source-sha256=4aeeb998a009a8c0c71e9477d00f398075340e4c6fcddbf6ae2c19a23e0d34d3 body-sha256=4e07b21dd33b2e8e4c7b456fdd1f20864f2d5d5dfb76a49419db8e724ddbf7e2 -->

# IEIT / Inspur

The AST2500 runtime exposes Linux SSH, the vendor SMASH/CLP console, IPMI, Redfish, and the vendor Web UI. The build keeps the original OpenSSH daemon and separates its two roles: `sysadmin/admin` enters BusyBox Linux, while `admin/admin` retains the vendor SMASH/CLP management interface.

## OEM IPMI command surface

The exact NF5468M6 image closes 324 registrations into 323 addresses and 950 documented direct and selector operations. zipmi owns the canonical [command reference](https://github.com/zenfish/zipmi/blob/main/docs/ieit-nf5468m6-command-reference.html) and [compact table](https://github.com/zenfish/zipmi/blob/main/docs/ieit-nf5468m6-command-table.html). Partial and unknown contracts, runtime BIOS-table replacement, and the `0x30/0xe2` provider collision remain explicit; inventory closure is not a claim that those boundaries are decoded.

## SSH and SMASH/CLP

    sudo ./tools/zbmc ieit ssh
    sudo ./tools/zbmc ieit ssh 'id; uname -a'
    sudo ./tools/zbmc ieit smash-clp

The selected address follows `zbmc`'s normal priority: per-box override, pool, then `zhosts.txt`. The IEIT build embeds that address in the guest image. After changing address configuration, run `zbmc ieit build` before starting the box; startup reports a mismatched image address.

These commands use the same preserved port-22 OpenSSH service but different accounts. The firmware synthesizes `admin` through its IPMI NSS/PAM modules and launches `/usr/local/bin/smashclp`. The local UID-0 `sysadmin` account originally used `/usr/local/bin/defshell` and was explicitly blocked by `DenyUsers sysadmin`. The rebuilt lab image changes only that local account to `/bin/sh`, assigns the standard lab password, and removes its deny rule. It does not replace sshd, PAM, NSS, or SMASH.

The health check runs a command through the Linux account and requires the exact marker `zbmc-ieit-linux-shell`. A TCP banner or successful SMASH prompt is not accepted as proof of a Linux shell.

### Why old runs called SSH unreliable

The original image contains no host keys. `/etc/init.d/ssh-main` backgrounds key generation, and the vendor script generates both RSA and DSA keys before starting sshd. Retained Debby runs reached authenticated SMASH at 134 and 282 seconds; other runs timed out waiting for SSH after IPMI, Redfish, and the Web UI were already ready. Commit `3cc7498` consequently removed SSH from required readiness and renamed it CLP. That was a readiness classification, not evidence that OpenSSH was absent. The current health contract restores SSH only after testing an actual remote Linux command.

## Copying files into the cold image

For this box, insert your file during the existing rootfs build. This is a local customization of the build recipe; dropping files beside the firmware does not insert them automatically.

1.  On the host, copy your ARMv6-compatible executable to `boxes/ieit/my-tool`.

2.  In your local [build-rootfs.sh](build-rootfs.sh), add this line immediately before `mkfs.cramfs "$ROOT" "$OUTPUT_CRAMFS"`:

        install -D -m 0755 "$HERE/my-tool" "$ROOT/usr/local/bin/my-tool"

    For a data file, use mode `0644` and the intended guest path instead.

3.  With the box stopped, rebuild and start from the repository root:

        ./build.sh ieit
        sudo ./tools/zbmc ieit start

The builder runs under `fakeroot` to preserve firmware metadata, rebuilds CramFS, and wraps it as a U-Boot ramdisk that QEMU loads separately from the boot flash. Keep its existing 35 MiB ramdisk-size check. Verify the published CramFS after rebuilding:

    verify_dir=$(mktemp -d)
    fakeroot -- fsck.cramfs --extract="$verify_dir" work/ieit/service-rootfs.cramfs
    cksum boxes/ieit/my-tool "$verify_dir/usr/local/bin/my-tool"

This installs `/usr/local/bin/my-tool` in the cold image. After rebuilding, run it through `sudo ./tools/zbmc ieit ssh /usr/local/bin/my-tool`. To run it automatically, you would still need an intentional startup-hook change. The serial socket remains available through `sudo ./tools/zbmc ieit console`. Keep the original pinned vendor download unchanged.

## Extracting the filesystem

The build publishes a CramFS service root. Extract it under `work/ieit/fs` and preserve its metadata with `fakeroot`:

    mkdir -p work/ieit/fs
    fakeroot -- fsck.cramfs --extract=work/ieit/fs work/ieit/service-rootfs.cramfs

The original configuration JFFS2 and Web UI CramFS remain packed in the source IMA.
