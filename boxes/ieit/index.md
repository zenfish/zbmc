<!-- html2md:auto source=boxes/ieit/index.html source-sha256=1a4dab007b3902d35a488bd3a7b37ac26abb4a96f4083f4286a97b1678eebfda body-sha256=ed995b63d1f4402e87f12dd46449fc2dfd0d9961d7a2fcb5c8f24216cec88b5c -->

# IEIT / Inspur

The AST2500 runtime exposes IPMI, Redfish, and the vendor Web UI. Its optional SSH transport runs SMASH/CLP, not a Unix shell. See the [shared file-transfer guide](../../README.md#copying-files-into-a-bmc) for boxes with an established live Linux shell.

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

This installs `/usr/local/bin/my-tool` in the cold image; it does not execute it or create a shell. To run it automatically, you would also need an intentional startup-hook change. The serial socket is available through `sudo ./tools/zbmc ieit console`, but a usable Linux login there has not been established. Keep the executable and build edit locally so they can be reapplied; the original pinned vendor download should remain unchanged.
