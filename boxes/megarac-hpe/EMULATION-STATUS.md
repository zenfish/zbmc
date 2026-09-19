<!-- html2md:auto source=boxes/megarac-hpe/EMULATION-STATUS.html source-sha256=54ce870bc5278fa9edd941b2891d83be757d3da9717394bd7464a14307c82792 body-sha256=aa26acef45716ce5848631126816c438b748ffd7556a9abe28bf77fe4d565deb -->

Current evidence · 2026-09-08

# MegaRAC-HPE rescue status

The HPE Cray XD670 MegaRAC image now cold-boots reproducibly on Debby and reaches the full declared management contract. This supersedes the 2026-08-21 snapshot-era status.

## Outcome: verified

Two clean boots of the same deterministic artifacts reached READY. Each accepted process recorded one kernel boot and one QEMU lifetime. Native authenticated IPMI, authenticated Redfish Managers, and the Web-UI session/dashboard path stayed healthy through a 60-second continuous hold.

## Acceptance runs

| Run | READY | Kernel boots in accepted log | Transient Redfish failures |
|----|----|----|----|
| 20260908T211524Z-34c76098-1cd1-4ba3-a7b7-77834184d1f3 | 432s | 1 | 21s and 26s into earlier holds |
| 20260908T212329Z-216bec40-69f3-4152-b9a7-64d32c180aab | 429s | 1 | 21s and 34s into earlier holds |

The 34-second regression directly disproves the old 30-second readiness hold. Both runs finally held all required services for 63 seconds before READY.

## Verified services

- ICMP at `10.250.0.40`.
- RMCP+ IPMI 2.0 on UDP/623 with Administrator account `admin`.
- Authenticated `/redfish/v1/Managers` returning the Manager Collection.
- Web-UI session, user lookup, administrator dashboard data, and clean logout.
- Interactive serial and an emulator-injected diagnostic shell path.

## Not claimed

- Vendor SSH or vendor SMASH/CLP.
- Rendered-browser screenshot or visual-layout validation.
- Warm restore with current QEMU.
- Behavior on real XD670 hardware.
- Injected Dropbear/telnet as vendor functionality.

## Failure chain and responsible fixes

### 1. Generated flash lacked firmware identity

Decoded: the original HPM contains a 0x140-byte firmware-info FMH at `0x3ef028f`, SHA-256 `fd6c69a5873f085947e7c29048ce85ba4b34bbfc7c7a23e439b60ea72693afbc`, with `FW_CODEBASEVERSION=5.X`. The old NOR omitted it.

### 2. Vendor helper returned incomplete FwInfo

Verified: `/proc/ractrends/Helper/FwInfo` lacked `FW_CODEBASEVERSION` with the incomplete flash.

### 3. GetDevID crashed

Decoded and dynamically reproduced: `GetDevID` passed a null source to `strncpy(destination, NULL, 8)`. That terminated IPMIMain before reliable management startup.

### 4. Builder preserves the FMH and owns the partition map

Verified: the builder copies the module unchanged to flash offset `0x3ef0000` and replaces `ami,spx-fmh` with fixed DT partitions: uboot 0–1MiB, conf 1–3MiB, bkupconf 3–5MiB, extlog 5–6MiB, www 6–10MiB, root 10–64MiB.

## Reproducibility

Two builds in independent directories compared equal with `cmp` for all four outputs. The builder verifies the HPM and fixes SquashFS metadata time to the vendor firmware epoch.

| Input/output | SHA-256 |
|----|----|
| Source HPM | 4e85590c2d5f18caf670b916522555347173ac277b098713c889303a7630cb76 |
| kernel.Image | 94843f212aaccfe311b34b874711ccbb387e5fe9d8a6caf4e3583bfbc18958e1 |
| dtb-a1.dtb | 57699dc066fd995075f234acd9b489461bda28a9e6f91b6b275363cb338b5939 |
| rootfs.sqfs | d757b2ee0654c7a125e24316d2cfcb05f5919d0962a6901f71f1f0a9a9239b62 |
| mtdflash.bin | d64412d0d0c13fc6bb03f52ea35bedf8762919a5c069c51a808e5e374b8e252e |

## Operational invariants

- Public warm start remains **BROKEN**; do not restore the obsolete snapshot.
- KCS1, KCS2, and KCS3 stay enabled because the QEMU AST2600 model supplies them.
- The early `/var/tmp/rc-init-complete` marker is not synthesized.
- IPMIMain output stays visible so the launcher can reject a real MsgHndlr SIGSEGV.
- READY depends on authenticated Managers, not public ServiceRoot, and all declared services must pass continuously for 60 seconds.
- The launcher owns cleanup on EXIT/signals and validates the selected QEMU process remains live.

## Historical correction

The old report said to always use a warm snapshot, described cold IPMIMain failure as an unresolved race, and treated protected Redfish as broken. Those statements are historical and superseded. Current QEMU rejects the old SRAM state; the cold image repair has two exact-input acceptance runs.

Operator commands: [README.html](README.md). Raw run evidence lives under `work/megarac-hpe/runs/` on Debby.
