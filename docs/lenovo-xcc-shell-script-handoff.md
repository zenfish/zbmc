<!-- html2md:auto source=docs/lenovo-xcc-shell-script-handoff.html source-sha256=ad23e1ef627ff1ec36567b69e9ab60567eda551a2c179cb0a4ac0a2cedb5ff55 body-sha256=a8ac83f790a7ba8838f6375752827a7764a4d3dc9c8fe59ed95ccc21b6dfb7b4 -->

Continuation record · 2026-09-23

# Lenovo XCC shell-script audit handoff

Operational context for resuming after conversation compaction. The full 191-entry report plus its SMI/SMM binary follow-up remain authoritative.

## Canonical state

- 191/191 scripts analyzed: hardware 84, services 59, security 48.
- Full report: [lenovo-xcc-shell-script-findings.html](lenovo-xcc-shell-script-findings.md).
- Catalog baseline commit `2926cea`; report artifact UUID `485be802-d991-400d-9afe-e03e20a40760`; current content UUID `4a5c4706-1492-5582-bcbe-26279e7c3877`.
- Source archive SHA-256: `35c631100b4b6b12a534bbfa8626fc143f15d52f42b2e7cdea58910dc0195425`.
- Corpus: `work/lenovo-xcc/shell-script-audit/`; durable Debby copy: `/home/zen/xcc-shell-audit-20260922`.

## Evidence boundary

We acquired the 191 shell scripts and a targeted static binary set from the XCC 6.92 SquashFS, not a complete live BMC. SquashFS SHA-256: `2aaedcb6c5939efabd49ac4da0a8066e17c5c3dea356ad33ad0d9246c4b192c2`. No known live MySQL dump, FFDC bundle, whole eMMC/GP/NOR image, `/pstorage`, `/gpx`, `/var/DS`, `/var/cmr`, active writable overlay, pending firmware bank, or host BIOS/SMM implementation has been acquired. Static firmware packages contain shipped defaults, not unit-specific runtime state.

## Highest-value findings

- Raw MDIO, I²C, FPGA/CIO, BMC-MMIO, VUART, NC-SI, IPMI, and VGPIO access.
- The firmware contains a real host-facing AST2600 X-DMA engine and complete driver, but Lenovo disables its DT node and omits the mandatory DMA memory region. This is separate from `hub_reset.sh`.
- `fpga_reset_pch.sh` physically resets the host PCH; PFR scripts expose host-firmware recovery/bank flows.
- `secure_erase.sh` and reset-to-defaults broadly erase persistent/security state.
- `port_fwd.sh` installs arbitrary DNAT/SNAT; `httpFuseMount.sh` mounts remote virtual media.
- Sensitive defects: LDAP password logging; SFTP password in argv and no host verification; predictable CSR files/fixed passphrase; Redis secrets in files/argv; `USERID:PASSW0RD`; CRL typo; stale statuses; nginx `eval`; unreachable webauth code.
- Five scripts have direct IBM copyright. Wider IMM/AMM naming is architectural inheritance, not proof of direct IBM authorship.

## Expanded follow-up findings

### MMIO versus host X-DMA

`memdump`, `peek`, and `poke` issue BMC ARM loads/stores through `/dev/mem`; that mechanism alone does not identify the far-side target. Strict-devmem blocks declared ordinary BMC System RAM. `hub_reset.sh` dumps 0x1000 bytes at 0x40800000 and toggles bit 6 at 0x408001a3, but the AST2600 datasheet leaves all of 0x40000000–0x4fffffff unassigned and Lenovo's DTB declares neither RAM, peripheral, nor PCIe window there. Static analysis therefore cannot distinguish stale/unmapped code from undocumented board logic or a hidden alias/bridge, and cannot exclude host reach. Lenovo's `libmod_sysfw.so` has an active `ipmi_usb_reset` handler that launches this script with `-d` for request 0 or `-h` for request 1; the script ignores that argument, and the caller configures no visible bridge first. This proves integration, not the decoder.

Separately, Lenovo's DTB contains `aspeed,ast2600-xdma` at 0x1e6e7000 and the shipped kernel contains its full driver. The driver accepts caller-selected 64-bit host addresses for host→BMC reads and BMC→host writes. Lenovo sets `status="disabled"` and omits the mandatory `memory-region`, so no normal device interface exists. Enabled MCTP-over-PCIe nodes show host-facing PCIe architecture, but live link, BusMaster, and IOMMU state are not acquired. This is the direct analogue of Supermicro ASPEED X-DMA.

Dell's different BCM5709 path is proved, not hypothetical: with VT-d off, the host NIC consumed a forged TX descriptor for physical page 0x10f34a000, looped the bytes internally into RX, and recovered PID 2257's `SECRET-DO-NOT-READ`/`Z3NDMA01` marker; a later 1 MiB range at 0x165a61000 yielded real RAM. Source is PhD commit `27f71aaaf` under `mobo/NIC/bcm5709/`. The May 14 `bmc/dell/t710-bmc-host-ram-state.html` is a pre-proof plan; `bmc/dell/iommu` is the July 22 experiment helper. `wpcm450-port/memdump-wpcm.c` reads only BMC-side WPCM450 MMIO.

### MDIO is PHY control, not DMA

The XCC 4.30 `mdio_peek_poke` attribute was mode 0666 and accepted one selector for read or `selector value` for write-and-readback. Its PHY address was fixed by the selected `xcc_eth.N` interface. Clause 22 reaches the low-five-bit register number; bit-30 encoded selectors reach Clause 45/MMD space on that same PHY. Values truncate to 16 bits, and failures still return a successful byte count. The traced path ends in bit-banged MDC/MDIO, so it can change link/PHY state but not MAC registers, descriptor rings, PCIe, X-DMA, BMC RAM, or host RAM. XCC 6.92 retains the scripts but its kernel no longer contains their endpoint, so they appear stale on the audited release.

### Front-panel USB

`ffdc_to_fp_usb.sh` expects the Pong Logical Device to switch a physical front-panel USB port from the host to the XCC's Pilot/Avocent USB host controller. It finds an `sd*` device under `/devtmpfs` associated with `/sys/devices/platform/ahb/`, mounts it at `/mnt/fp_usb`, copies IMM FFDC, and unmounts. Exact mux/GPIO, connector, filesystems, and Pong implementation are unknown; ancestry checking is weak.

### NMI and fixed SMI output

`IPMICmd 0x20 0x00 0x00 0x02 0x04` in `pwrctrl.sh` is standard Chassis Control / Pulse Diagnostic Interrupt: a host NMI, not a power cycle. Its external caller and authorization remain unknown. On AMD systems, `amd_sync_rtc.sh host` checks FPGA bank 16/offset 8 for `1e`, then pulses bank 15/offset 3 bit 5 while forcing bit 6 low. This is a fixed “sync time” SMI notification with no payload, acknowledgement, or selectable handler shown.

### General SMI device

`libmod_reset` binds `smi_out`, `smi_warn`, `smi_source`, `smi_state`, and `smi_mask_port`. It can queue at most four one-byte request codes, assert/deassert the SMI output, enable/disable the source, apply timeouts, and re-arm periodically. Directed event `1004` queues one request byte. The initializer registers OEM NetFn `3a` commands `19`, `1a`, and `1b` for state, timeout, and enable/control handlers. Exact per-command mapping and exposure through LAN/Redfish/UI are unresolved.

### KCS-SMM nonce and request channel

The BMC consumes a 32-byte SMEM object named `secure_nonce`, copies it to `0x1000f000`, and zeroes the source. UEFI/SMM returns bytes 0–15 through the TWR window at `0x1e789240` and bytes 16–31 as a KCS-request prefix. The BMC compares both halves, rejects mismatches and all-zero values, strips the 16-byte prefix, and accepts only NetFn/Cmd `2e/{90,92}`, `3a/{38,7d,7f,c4,cd,da}`, and `0a/49`; other commands receive `d5`. The BMC returns an ordinary KCS/IPMI response without the nonce. This proves authenticated host-SMM→BMC requests and BMC→host responses, not unsolicited BMC→SMM payload delivery.

Both nonce and whitelist checks fail open in code when their callback pointer is null. Normal state-machine initialization registers both, so practical exploitation is not proved; startup/load-order reachability remains a research question.

### Memory-fault SMI plus data

`mem_register_logical_device` uses either FPGA signals `SPARE_PCH_FPGA_PGPPA_N`/`...BIT6` or GPIO `BMC_SMI_OUT` as a one-bit SMI doorbell. OEM NetFn `3a`/Cmd `cd` separately exchanges fault, recovery, PPR, and memory-configuration records; the BMC clears the signal when the host reports receipt. This is data associated with an SMI, but the data travels through OEM IPMI/storage rather than in the SMI or demonstrated SMRAM writes.

### Two meanings of SMM

`KCS-SMM`, nonce/TWR, UEFI, and CPU SMI refer to x86 System Management Mode. `smm_logical_device`, `smmless_logical_device`, PSoC, PSU/node power, and `/v2/ibmc/smmless/...` refer to a chassis System Management Module or module-less chassis. The latter is bidirectional BMC↔PSoC I²C and is not an x86-SMM bypass. Its OEM NetFn `3a`/Cmd `f5` supports mode, timeout, reseat/reset, and bounded VPD reads/writes. The shell condition `[ $((PLATFLAGS & MASK_SMMLESS)) ]` is always true even when the result is zero; that bug affects PSoC/network and FFDC branches, not CPU SMM.

### MySQL

Required schemas are `immdb`, `dmdb`, `propertiesdb`, and `vpd_db`. Hot backup is `mysqldump --single-transaction --quick --all-databases --insert-ignore`, including system schemas/grants. Paths: `/var/lib/mysql`, `/var/keep/mysql/mysql-backup.tzz`, `mysqldumpfull.sql.gz` plus old/bad variants, and `/var/keep/mysql/recovery/`. Normal IMM FFDC includes full SQL dumps without field-level sanitization. Capability is proven; an actual dump is not acquired.

### VGPIO and WHEA

NetFn `2e`/Cmd `92` is registered for OEM IDs `004f4d` and Lenovo `004a66`. The request carries a 32-bit network-order logical address, operation, and event ID. Operations are `00` assert, `01` deassert, `02` query, and `80` AssertWHEA. A VGPIO address identifies a configured node/group/class/subclass/instance object and event mapping—not a Linux GPIO, direct pin, MMIO address, or unrestricted write primitive. `AssertWHEA` creates a configured VGPIO/SEL event and later writes an 18-byte `GPIO` v2 record to fixed datastore `whea-data`; filtered CPU SELs independently produce 24-byte `IBMC` v1 records. This can synthesize telemetry and consume SEL/aux-log space, but no direct SMI, host-memory write, or downstream host acceptance is proved. Outer IPMI transport privilege and exposure are unresolved.

### eMMC

`check_emmc.sh` reads only EXT_CSD byte 156 from `/dev/mmc0` and validates pSLC attributes; manufacturing request is `ipmitool raw 0x2e 0x01 0x66 0x4a 0x00`. A logical user-area image is likely possible. A complete acquisition additionally needs boot/GP partition nodes and full EXT_CSD; RPMB needs authenticated commands/key. Controller internals and deleted physical flash pages are not implied readable.

### FFDC push

`ffdc_dump.sh` describes a `bmc_app` FFDC logical device and IPMI `4Ah` Push File Request; exact binary dispatch/authorization is missing. Types: full IMM dump under `/gpx/ftphome/download/ffdc/imm_dump`, Call Home under `.../ffdc_dump`, and SOL under `/gpx/sol_dump` (with likely source-name bug). Full FFDC can include access/configuration, logs, VPD, UEFI/PLDM, firmware state, cores, much of `/flash/data0`, and full SQL dumps. TFTP is unauthenticated; SFTP disables host verification and exposes password in argv. Completion is recorded without checking transfer success.

### Secure erase acquisition list

Before destructive work capture `/.xcc-fw/{primary,backup,recovery}/rw`, `/.xcc-fw/keepfiles`, `/.whitelist`, every `/.xcc-fw/pending-*`, `/gpx`, `/var/cmr`, `/var/DS`, and all `/pstorage`. The script unlinks regular files then calls enhanced reset, which sets FPGA bank 1 offset `0x0A` to 1 and reboots. It preserves `bios.*`, `flash_history.log`, and paths containing `oem`. This is not proven cryptographic erasure; early-boot handling of the secure-wipe bit is unknown.

### PFR/PCH recovery

PCH is the Intel Platform Controller Hub; recovery covers host SPI Flash Descriptor, BIOS/UEFI, and SPS/ME regions. The script says `pfr_ld` inside `bmc_app` calls it after deciding flash ID 1 needs recovery; no IPMI/Redfish/web trigger is proven. It chooses trusted then candidate BIOS packages, extracts platform FD, derives/erases SPS, programs FD, toggles FPGA PCH reset/power-good, tests MAFS, asserts `ME_SECURITY_OVERRIDE`, flashes UPD, clears override, and tests again. Defects: unused authentication result; structural-only checks here; ignored SPS erase errors; lost flash status; commented reauthentication; stale PID and persistent cleanup/override hazards.

## Next work, in order

1.  On real XCC hardware, read—but do not yet change—the XDMA/PCIe gates at 0x1e6e20c0, 0x1e6e20c8, 0x1e6e2c20, 0x1e6e2c68, 0x1e6ed0c0, and 0x1e6e7000–0x1e6e7074; correlate with host `lspci`, BusMaster, and IOMMU state.
2.  Acquire host BIOS/UEFI/SMM binaries to identify the SMI handlers, queued request-code meanings, nonce producer/consumer, and `whea-data` consumer.
3.  Trace outer IPMI policy and transport routing for NetFn/Cmd `3a/{19,1a,1b,cd,f5}` and `2e/92`; do not equate internal registration with LAN reachability.
4.  Create and preserve full IMM FFDC with hashes.
5.  Acquire hot logical and cold physical MySQL artifacts; enumerate schemas/tables/users/grants.
6.  Archive every secure-erase target and image every readable eMMC/NOR region before destructive work.
7.  Acquire missing `pfr_ld`, Pong, FFDC-device, flash-manager, KCS-driver/provider, and datastore-provider binaries.
8.  Only then test destructive/recovery, SMI, or X-DMA paths on a controlled copy or sacrificial system.

## Cold boot and Debby

No shell evidence changes the cold-boot result: `bmc_app` remains blocked on missing chassis peers; do not resume broad cold work absent new evidence. Debby's NVMe namespace disappeared beneath mounted root while PCI remained present. Post-reboot SMART showed no media errors; controller firmware/APST/reset recovery leads, then PCIe path and SSD controller. Report: `/Users/zen/limbo/analyzing-dead-debby.html`.

## Operating constraints

- Owner authorizes encrypted or unencrypted transfer of any scripts/data among owner-controlled `10.0.0.0/8` systems.
- Prefer direct recoverable copies; avoid ephemeral-only handling and secrecy theater.
- Explain implications, exact inputs, ignored statuses, callers, assumptions, and unknowns.
- Do not claim acquisition or trigger merely because a script supports it.
