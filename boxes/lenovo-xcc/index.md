<!-- html2md:auto source=boxes/lenovo-xcc/index.html source-sha256=51a7aa526757cc53d1f1f0fdd8b98395d27bf7e410011e39d76d0248117e68e6 body-sha256=161b1267c889a73bc7891455147df16d04979125cd0c0bf226ca640ed8bfcdda -->

zbmc / preserved firmware

# Lenovo XClarity Controller

A cold-boot runtime for Lenovo XCC 6.92 on an AST2600 model with an experimental FPGA transport and eMMC GP0 implementation.

## Verified remote IPMI — warm restore, 2026-09-10

A matched RAM and full-disk checkpoint passed three authenticated IPMI reads after an independent restore. The normal managed entry restored a second instance and reached READY in 94 seconds, with authenticated IPMI stable for 68 seconds. Cold boot still fails to restore usable native account services; use the explicit warm path.

    cd ~/src/oob/zbmc
    sudo ./tools/zbmc lenovo-xcc start --warm --no-web
    sudo ./tools/zbmc lenovo-xcc ipmi mc info
    sudo ./tools/zbmc lenovo-xcc ipmi chassis status

Debby deployment: 10.250.0.45, standard UDP/623; private zbmc.conf supplies ZBMC_LENOVO_DIR and ZBMC_LENOVO_PASSWORD. USERID uses a changed password, not the factory password. Checkpoint files are private and are not distributed by build.sh. The preserved original and validation VMs remain paused on separate addresses/ports.

Restore requires the matched ckpt/state.gz and ckpt/emmc.qcow2, recorded boot artifacts, and exact QEMU SHA-256 0239888e57aeb1f73508f90eddd042f295988a275145a9717b0878cda041da69. ckpt/manifest.json records hashes. Native authentication and account/channel permissions remain enforced. Snapshot restore discards changes made after capture; provisioned settings are stored in the captured state.

Observed warm HTTPS root returns 200, but web-login correctness is not part of this IPMI acceptance. The cold-only observations below are historical, not current remote-IPMI readiness claims.

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

Lenovo's DHCP hook receives QEMU's lease but its `avctifconfig` control path does not install the accepted address in Linux. The emulator-only getty hook waits for Lenovo's own DHCP completion marker, then installs QEMU user networking's fixed `10.0.2.15/24` address and `10.0.2.2` default route. Health probing waits for both this network marker and the vendor's Web-Available marker.

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

## Authenticated remote IPMI

Verified on 2026-09-09 with both standard ipmitool and zipmi: repeated controller information and chassis status reads succeed using cipher suite 17. Account role and IPMI channel privilege are separate: the native Administrator role did not grant channel access until standard local `ipmitool user priv 2 4 1` set channel 1, user 2 to ADMINISTRATOR.

Provision through supported management interfaces: change the mandatory factory password, enable IPMI for USERID and globally with native users/portcontrol, then verify the channel privilege. Preserve the provisioned disk: normal runtime writes use a temporary overlay. Factory image builds do not contain this account change. A saved provisioned disk is under managed cold-boot verification. The launcher uses fdtget/fdtput from device-tree-compiler to derive a separate kernel-runtime.zImage: only appended device-tree boot arguments change, adding the native 1800-second Gunicorn startup timeout. This firmware ignores the external QEMU -append value.

    # In private, mode-0600 zbmc.conf:
    ZBMC_LENOVO_PASSWORD='your-provisioned-password'

    ./tools/zbmc lenovo-xcc ipmi mc info
    ./tools/zbmc lenovo-xcc ipmi chassis status

The command and readiness paths use the same password-authenticated ipmitool call, with the password passed through its environment. IPMI readiness requires a successful controller read. SSH and Redfish are outside the readiness contract; successful IPMI does not establish Web login health.

Large artifacts are SHA-256 pinned at git.trouble.org. Firmware remains subject to its vendor license.
