# zbmc NVIDIA OpenBMC

## Extracting the filesystem

The build artifact is a complete flash image. Extract embedded filesystems into `work/nvidia-obmc/fs`:

    mkdir -p work/nvidia-obmc/fs
    binwalk -eM -C work/nvidia-obmc/fs work/nvidia-obmc/flash.mtd

If binwalk is unavailable, locate the `hsqs` signature and use `unsquashfs -o OFFSET -d work/nvidia-obmc/fs/rootfs work/nvidia-obmc/flash.mtd`. Keep `flash.mtd` packed for normal boots.
