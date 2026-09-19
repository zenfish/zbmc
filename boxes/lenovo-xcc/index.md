<!-- html2md:auto source=boxes/lenovo-xcc/index.html source-sha256=cc3c26ac3ab1f2d74b62215f641c9fef18fe7bc5aaa2dfdc78d2b7e406d2db0a body-sha256=7e746aee4f49c9aa4f8eeac1bce8b70d09bdcb1cda9713d4acf536ae23144aec -->

zbmc / preserved firmware

# Lenovo XClarity Controller

A cold-boot runtime for Lenovo XCC 6.92 on an AST2600 model with an experimental FPGA transport and eMMC GP0 implementation.

Verified

HTTPS 200

Vendor page identifies as XCC Web Server and Lenovo XClarity Controller 2.

Cold only

~46 minutes

The default contract reached READY on Debby in 46m06s, including the 60-second hold.

Not declared

IPMI / SSH

UDP/623 receives requests without replies. SSH resets before key exchange.

## What the runtime changes

The kernel and signed rootfs are preserved. The built-in initramfs adds a runtime observer and replaces `vpdoctor` with a sleeping process because the physical watchdog/platform contract is unavailable. The AST2600 watchdog remains modeled, but QEMU ignores its reset action: under slower TCG execution it expires before XCC finishes starting services. The SRAM image selects Newyork-pass1 but is reconstructed from preserved platform assets; it is not a physical SRAM capture.

## Run

    ./tools/zbmc lenovo-xcc build
    sudo ./tools/zbmc lenovo-xcc start
    ./tools/zbmc lenovo-xcc web
    ./tools/zbmc lenovo-xcc status

## Pinned inputs

- Preserved zImage with block-spliced observer initramfs
- Lenovo DTB, reconstructed SRAM, and PTABLES
- Compressed 7 GiB initialized eMMC image
- QEMU 11 FPGA/eMMC GP0 patch with bounded tracing

## Copying files

The current runtime has no established arbitrary-file transfer recipe. SSH resets before key exchange, so the [shared SSH upload commands](../../README.md#copying-files-into-a-bmc) do not work. `sudo ./tools/zbmc lenovo-xcc console` attaches the interactive serial socket, but socket access alone does not establish a Linux shell or usable login.

The kernel/initramfs already contains an observer used during bring-up; it is not a host-directory mount or file-upload interface. Inserting another executable into that boot path requires a custom image build. The signed vendor rootfs remains preserved; copying into `work/lenovo-xcc/` or uploading through the firmware-update UI is not a documented way to install a program inside the BMC.

Large artifacts are SHA-256 pinned at git.trouble.org. Firmware remains subject to its vendor license.
