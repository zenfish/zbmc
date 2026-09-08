<!-- html2md:auto source=boxes/megarac-hpe/README.html source-sha256=4f8501a27f5254386d73d83b4e1c6b34a2b463222f98ea2269f93cc5cd877f5a body-sha256=eb74f109c5e62bd350d9a6adbf5c1595d05818313fd63a1693a4d8acac455784 -->

zbmc box · verified 2026-09-08

# HPE XD670 MegaRAC on QEMU

A cold boot of the preserved AMI MegaRAC SP-X firmware on the AST2600 model. Native IPMI, authenticated Redfish, and the vendor Web-UI login/dashboard path are required.

## IPMI

Verified RMCP+ on UDP/623 with `admin`/`superuser`.

## Redfish + Web UI

Managers plus Web-UI session/dashboard APIs must stay healthy for 60 seconds.

## Warm start

Broken: the saved ASPEED SRAM is 0x17000 bytes; current QEMU requires 0x18000.

## Start and use it

    export ZBMC_POOL=10.250.0
    sudo -E ./tools/zbmc megarac-hpe up --deadline 900
    ./tools/zbmc megarac-hpe status
    ./tools/zbmc megarac-hpe ipmi mc info
    curl -sk -u admin:superuser https://10.250.0.40/redfish/v1/Managers
    sudo -E ./tools/zbmc megarac-hpe stop

Expected cold READY time is about seven minutes. Authenticated Managers alternated between success and failure twice during initialization; READY is withheld until all functional probes remain healthy through the full hold.

## What was repaired

1.  Firmware-info FMH preserved. The generated NOR had omitted the 0x140-byte module at HPM offset `0x3ef028f`. Without it, `/proc/ractrends/Helper/FwInfo` lacked `FW_CODEBASEVERSION`, and `GetDevID` called `strncpy(destination, NULL, 8)`.
2.  Fixed partitions encoded in the DTB. The QEMU image uses explicit uboot, conf, bkupconf, extlog, www, and root ranges instead of vendor `ami,spx-fmh` discovery.
3.  The accepted rootfs behavior restored. KCS1–3 remain enabled; the premature `rc-init-complete` marker, SIGSEGV preload tracer, and timing-gate heartbeat are absent. IPMIMain diagnostics remain visible.
4.  Readiness made functional. IPMI, authenticated Redfish Managers, and the Web UI's own session/dashboard APIs are all required continuously for 60 seconds.

## Rebuild from the HPM

    boxes/megarac-hpe/build-from-hpm.sh work/megarac-hpe-build

The builder verifies HPM SHA-256 `4e85590c2d5f18caf670b916522555347173ac277b098713c889303a7630cb76`, fixes the SquashFS creation time, and normalizes patched files to the firmware build epoch. Two independent builds compared byte-for-byte equal. The accepted bundle is published without replacing historical files under `megarac-hpe/cold-20260908/`.

| Artifact | SHA-256 |
|----|----|
| kernel.Image | 94843f212aaccfe311b34b874711ccbb387e5fe9d8a6caf4e3583bfbc18958e1 |
| dtb-a1.dtb | 57699dc066fd995075f234acd9b489461bda28a9e6f91b6b275363cb338b5939 |
| rootfs.sqfs | d757b2ee0654c7a125e24316d2cfcb05f5919d0962a6901f71f1f0a9a9239b62 |
| mtdflash.bin | d64412d0d0c13fc6bb03f52ea35bedf8762919a5c069c51a808e5e374b8e252e |

## Evidence boundary

The normal contract verifies vendor IPMI and Redfish plus successful Web-UI session creation and administrator dashboard data. A rendered-browser screenshot was unavailable in this session. Vendor SSH is absent. Optional injected Dropbear, telnet, direct root console, and SMASH replacement are diagnostic substitutions; enable them only in an isolated lab with `ZBMC_INSECURE_LAB_ACCESS=1`.

Detailed evidence: [EMULATION-STATUS.html](EMULATION-STATUS.md).
