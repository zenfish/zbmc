<!-- html2md:auto source=boxes/lenovo-xcc/index.html source-sha256=70b17b5371cead7c8679282e14cbf851a8250a68048b70ffb5cb9cdb27f00894 body-sha256=28b1b87dbb5bcd07bb9ccd0a977a5a1024478554e4a553a2c096b7fbfafbd6d9 -->

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

Large artifacts are SHA-256 pinned at git.trouble.org. Firmware remains subject to its vendor license.
