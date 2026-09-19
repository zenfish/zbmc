# zbmc Advantech ASMB-787

## Extracting the filesystem

`build.sh` leaves the FMH-carved inputs in `work/advantech-asmb787/unpacked`. Extract the patched root filesystem into the requested tree:

    mkdir -p work/advantech-asmb787/fs
    RSQ=$(find work/advantech-asmb787/unpacked/fw-blobs -name 'sqsh_*.sqsh' -type f -printf '%s %p\n' | sort -nr | head -1 | cut -d' ' -f2-)
    unsquashfs -d work/advantech-asmb787/fs/rootfs "$RSQ"
    find work/advantech-asmb787/unpacked/fw-blobs -name 'sqsh_*.sqsh' -print

To recover the configuration JFFS2 regions as well, run `jefferson -f -d work/advantech-asmb787/fs/conf <region.jffs2>` on the carved files. `rootfs.sqfs` is the QEMU-patched copy; the command above reads the vendor tree.
