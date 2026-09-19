# zbmc Supermicro X10

## Extracting the filesystem

X10 contains a CramFS payload at the fixed flash offset `0x400000`. Extract it without flattening symlinks:

    mkdir -p work/supermicro-x10/fs
    dd if=firmware/x10-master.flash of=work/supermicro-x10/fs/rootfs.cramfs bs=4096 skip=1024 count=3730
    fakeroot -- fsck.cramfs --extract=work/supermicro-x10/fs/rootfs work/supermicro-x10/fs/rootfs.cramfs
    dd if=firmware/x10-master.flash of=work/supermicro-x10/fs/web.cramfs bs=4096 skip=5888 count=1805
    fakeroot -- fsck.cramfs --extract=work/supermicro-x10/fs/web work/supermicro-x10/fs/web.cramfs

The original flat flash remains the boot input; the extracted tree is for inspection or preparing a separate custom image.
