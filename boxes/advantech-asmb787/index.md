# zbmc Advantech ASMB-787

## Extracting the filesystem

`build.sh` leaves the FMH-carved inputs in `work/advantech-asmb787/unpacked`. Extract the patched root filesystem into the requested tree:

    mkdir -p work/advantech-asmb787/fs
    RSQ=$(find work/advantech-asmb787/unpacked/fw-blobs -name 'sqsh_*.sqsh' -type f -printf '%s %p\n' | sort -nr | head -1 | cut -d' ' -f2-)
    unsquashfs -d work/advantech-asmb787/fs/rootfs "$RSQ"
    find work/advantech-asmb787/unpacked/fw-blobs -name 'sqsh_*.sqsh' -print

Extract every embedded filesystem from the packed NOR as well:

    mkdir -p work/advantech-asmb787/fs/{rootfs,www,conf,bkupconf,dre}
    mapfile -t sqsh < <(find work/advantech-asmb787/unpacked/fw-blobs -name 'sqsh_*.sqsh' -type f -printf '%s %p\n' | sort -nr | cut -d' ' -f2-)
    unsquashfs -d work/advantech-asmb787/fs/rootfs "${sqsh[0]}"
    unsquashfs -d work/advantech-asmb787/fs/www "${sqsh[1]}"
    for spec in "0xd0000 0x1f0000 conf" "0x2d0000 0x1f0000 bkupconf" "0x2e10000 0 dre"; do
      set -- $spec; args=(if=firmware/encrypted_ASMB-787_20220912.ima_enc of="work/advantech-asmb787/fs/$3.jffs2" bs=1 skip=$(( $1 )) status=none)
      [ "$2" = 0 ] || args+=(count=$(( $2 )))
      dd "${args[@]}"
      jefferson -f -d "work/advantech-asmb787/fs/$3" "work/advantech-asmb787/fs/$3.jffs2"
    done

The rootfs artifact is the QEMU-patched copy; the other trees come from the original firmware.
