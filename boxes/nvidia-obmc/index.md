# zbmc NVIDIA OpenBMC

## OEM IPMI command surface

The pinned GB200 image contains one NVIDIA OEM provider with eight operations. zipmi's canonical
[command reference](https://github.com/zenfish/zipmi/blob/main/docs/nvidia-gb200-command-reference.html)
and [compact table](https://github.com/zenfish/zipmi/blob/main/docs/nvidia-gb200-command-table.html)
account for their privilege, request/response layouts, effects, activation, and named execution.
Only one operation has retained live evidence; physical host-interface dependencies remain a runtime
boundary rather than an inventory gap.

## Extracting the filesystem

The build artifact is a complete flash image. Extract embedded filesystems into `work/nvidia-obmc/fs`:

    mkdir -p work/nvidia-obmc/fs
    binwalk -eM -C work/nvidia-obmc/fs work/nvidia-obmc/flash.mtd

If binwalk is unavailable, locate the `hsqs` signature and use `unsquashfs -o OFFSET -d work/nvidia-obmc/fs/rootfs work/nvidia-obmc/flash.mtd`. Keep `flash.mtd` packed for normal boots.
