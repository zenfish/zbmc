<!-- html2md:auto source=boxes/lenovo-xcc/index.html source-sha256=a00123ee0c56c47c5603e3577c02b04822cc6205e8d0f64dc53bcdbb46903cb2 body-sha256=e3c323766bdc533fae740cd07de03bd4f125ba3072a94870f16fa85e1ce6da64 -->

zbmc / preserved firmware

# Lenovo XClarity Controller

A cold-boot runtime for Lenovo XCC 6.92 on an AST2600 model with an experimental FPGA transport and eMMC GP0 implementation.

Verified

HTTPS 200

Vendor page identifies as XCC Web Server and Lenovo XClarity Controller 2.

Cold only

~46 minutes

The default contract reached READY on Debby in 46m06s, including the 60-second hold.

Verified

Serial root shell

The host-local console socket provides an emulator-only diagnostic shell; network SSH remains disabled.

## What the runtime changes

The kernel and signed rootfs are preserved. The built-in initramfs adds a runtime observer and replaces `vpdoctor` with a sleeping process because the physical watchdog/platform contract is unavailable. The AST2600 watchdog remains modeled, but QEMU ignores its reset action: under slower TCG execution it expires before XCC finishes starting services. The SRAM image selects Newyork-pass1 but is reconstructed from preserved platform assets; it is not a physical SRAM capture.

## Run

    ./tools/zbmc lenovo-xcc build
    sudo ./tools/zbmc lenovo-xcc start
    ./tools/zbmc lenovo-xcc console
    ./tools/zbmc lenovo-xcc web
    ./tools/zbmc lenovo-xcc status

## Pinned inputs

- Preserved zImage plus a deterministic block-spliced serial-shell derivative
- Lenovo DTB, reconstructed SRAM, and PTABLES
- Compressed 7 GiB initialized eMMC image
- QEMU 11 FPGA/eMMC GP0 patch with bounded tracing

## Diagnostic console

Lenovo’s normal `lcw_login` requires a response signed by a vendor debug key that is not present in the firmware. The derived kernel changes only the built-in initramfs: before normal `switch_root`, it bind-mounts an emulator-only getty launcher over the serial login script. The original kernel, eMMC, root filesystem, and appended DTBs remain unchanged. Access is limited to the host Unix socket exposed by `zbmc console`.

Large artifacts are SHA-256 pinned at git.trouble.org. Firmware remains subject to its vendor license.
