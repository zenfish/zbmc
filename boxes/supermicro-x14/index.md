# zbmc Supermicro X14

## OEM IPMI command surface

The 01.01.06.07 baseline and audited 01.07.00.06 additions close 248 documented operations over 67
addresses. zipmi's canonical [command reference](https://github.com/zenfish/zipmi/blob/main/docs/supermicro-x14-command-reference.html)
and [compact table](https://github.com/zenfish/zipmi/blob/main/docs/supermicro-x14-command-table.html)
retain the 58 partial request layouts, 63 partial response layouts, seven operations without distinct
named routes, and system-interface-only boundaries. Inventory closure is not full field decoding.

## Extracting the filesystem

The root filesystem is SquashFS at the start of eMMC partition 9 (offset `0x500000`). Extract it directly, then use `guestfish` to copy writable partition 17 if needed:

    mkdir -p work/supermicro-x14/fs/rofs
    unsquashfs -o 5242880 -d work/supermicro-x14/fs/rofs work/supermicro-x14/emmc.img
    mkdir -p work/supermicro-x14/fs/rwfs
    guestfish --ro -a work/supermicro-x14/emmc.img -m /dev/sda17:/ tar-out / - | tar -xpf - -C work/supermicro-x14/fs/rwfs

Extract the boot initramfs separately:

    mkdir -p work/supermicro-x14/fs/initramfs
    xz -dc work/supermicro-x14/initramfs-patched.bin | (cd work/supermicro-x14/fs/initramfs && cpio -idm --no-absolute-filenames)

`x14-ce0-64m.img` is NOR flash and is kept packed. See [REPRODUCE.md](REPRODUCE.md) for the boot artifact layout.
