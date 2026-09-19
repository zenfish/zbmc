# zbmc Supermicro X14

## Extracting the filesystem

The root filesystem is SquashFS at the start of eMMC partition 9 (offset `0x500000`). Extract it directly, then use `guestfish` to copy writable partition 17 if needed:

    mkdir -p work/supermicro-x14/fs/rofs
    unsquashfs -o 5242880 -d work/supermicro-x14/fs/rofs work/supermicro-x14/emmc.img
    mkdir -p work/supermicro-x14/fs/rwfs
    guestfish --ro -a work/supermicro-x14/emmc.img -m /dev/sda17:/ tar-out / - | tar -xpf - -C work/supermicro-x14/fs/rwfs

`x14-ce0-64m.img` is NOR flash and is kept packed. See [REPRODUCE.md](REPRODUCE.md) for the boot artifact layout.
