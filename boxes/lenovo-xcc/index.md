<!-- html2md:auto source=boxes/lenovo-xcc/index.html source-sha256=c6fbf809f7986765c97298c4a60891823ef9f194d6aaaed6d6e25e35b0fb40f9 body-sha256=5ec3825a425bf5368ed92189d145a9b3ed53fe0a2c8be4c29129657972f5dcbe -->

zbmc / preserved firmware

# Lenovo XClarity Controller

A cold-boot runtime for Lenovo XCC 6.92 on an AST2600 model with an experimental FPGA transport and eMMC GP0 implementation.

Verified

HTTPS 200

Vendor page identifies as XCC Web Server and Lenovo XClarity Controller 2.

Cold only

~6 minutes

Web-ready at guest uptime 364 seconds; verified again after the 60-second hold.

Not declared

IPMI / SSH

UDP/623 receives requests without replies. SSH resets before key exchange.

## What the runtime changes

The kernel and signed rootfs are preserved. The built-in initramfs adds a runtime observer and replaces `vpdoctor` with a sleeping process because the physical watchdog/platform contract is unavailable. The SRAM image selects Newyork-pass1 but is reconstructed from preserved platform assets; it is not a physical SRAM capture.

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

Large artifacts are SHA-256 pinned at git.trouble.org. Firmware remains subject to its vendor license.
