# Fix GitHub contract workflow

- [x] Inspect the original and follow-up GitHub Actions logs.
- [x] Reproduce the new iLO5 contract locally.
- [x] Replace Ubuntu's incompatible `Cryptodome` package with an isolated PyPI `Crypto` environment.
- [x] Add targeted `.md` / `.html` arguments to `tools/sync-docs`.
- [x] Cover single-file, generated-file, and multiple-file selection.
- [x] Verify focused and full contract suites and inspect the final diff.

## Review

The iLO5 firmware-unpacking CI test failed because Airbus's iLO5 decryption scripts import `Crypto.Cipher.AES`, while the clean runner lacked that Python namespace. Two follow-up runs proved Ubuntu's `python3-pycryptodome` package was installed and its Python selected, but Debian-family packaging exposes `Cryptodome`, not the upstream toolbox's expected `Crypto` namespace. CI now creates an isolated venv with pinned PyPI `pycryptodome` 3.23.0, and the iLO5 reproduction guide uses the same dependency boundary. This work is unrelated to the Lenovo XCC investigation below.

`tools/sync-docs` also accepts one or more `.md` or `.html` selectors, preserves those selectors during post-write verification, and leaves its no-argument repository-wide behavior unchanged.

Verified with `python3 -m py_compile tools/sync-docs`, `bash tests/sync-docs-cli.sh`, targeted Markdown/HTML checks, `bash tests/run`, and `git diff --check`.

# Integrate Lenovo XCC

- [x] Build and pin the Lenovo-specific QEMU 11 runtime.
- [x] Publish and hash-pin the preserved cold-boot artifacts.
- [x] Add the standard address allocation, cold boot, and WebUI readiness contract.
- [x] Synchronize the HTML and Markdown operator documentation.
- [x] Cold-boot and verify the 60-second stability hold on Debby.

## Review

The Lenovo XCC runtime preserves the vendor kernel and root filesystem, adds the minimum platform emulation required for the FPGA/eMMC startup path, and declares only the reproduced vendor WebUI. IPMI and SSH remain explicitly disabled in the service contract. Warm start remains unadvertised until migration is tested successfully.

Debby run `20260902T071810Z-f43e4719-cfe5-49fe-b034-69bed9d53719` survived the former 16-minute watchdog-reset boundary and reached terminal READY in 46m06s with the vendor WebUI healthy through its 60-second hold. QEMU's watchdog reset action is suppressed while the AST2600 watchdog remains modeled. The cold readiness deadline is 60 minutes. The focused runtime test, full repository suite, and all documentation pairs pass.

# iLO5 svcsILO bring-up

## Review

The live Debby run in `work/ilo5-debby-attempt-139/renode.log` proved the tracked `gxp_dev.py` fix is on-path and changes behavior in the previously blocked svcsILO startup region. Before the fix, repeated control-register reads after event-service init returned `0x0`; with the fix, the same run shows persisted read-backs like `off=0xb0 -> 0x808`, `off=0xc4 -> 0x704`, and `off=0xa0 -> 0x101` before the guest clears them.

That run also reaches `SVCSILO_MAIN`, crosses `phase=after-event-service-init`, and continues to later `ILOMAIN_COMMAND` handling. This verifies the narrowest correct change in the device model: preserve non-mailbox register writes so later firmware reads can observe guest-programmed state.

# Migrate iDRAC10 management networking to TAP

- [x] Put `10.250.0.31` on the guest GMAC via `ztap-idrac10` with stable MAC `52:54:00:fa:00:31`.
- [x] Remove the host management alias and management `hostfwd`; retain isolated USB SLiRP only for bootstrap payloads.
- [x] Validate cold ARP, ICMP, SSH, authenticated IPMI, and protected Redfish through zBMC.
- [x] Create a TAP-native checkpoint and validate the warm restore through zBMC.

## Review

Cold run `20260910T212003Z-12971c7d-88e8-4f8c-a19f-b87aa4a6a6ce` reached READY for ICMP, SSH, authenticated IPMI `mc info`, and protected Redfish. Its ARP entry maps `10.250.0.31` to `52:54:00:fa:00:31`; the host has no `.31` address; and the QEMU management NIC is TAP-backed with no management `hostfwd`.

Warm run `20260910T214232Z-a11c6152-44a9-4cfc-a313-b1fece55a4c6` restored the marker `tap ztap-idrac10 52:54:00:fa:00:31 10.250.0.31` and reached the same four-service READY contract in 2m47s. Exact topology and probe output is preserved in each run's `probes/tap-validation.txt` or `probes/tap-warm-validation.txt`.

# Filesystem extraction documentation

- [x] Add a main README index for extracting each zoo BMC filesystem into `work/<box>/fs`.
- [x] Add per-BMC extraction recipes, including packed-only and format caveats.
- [x] Add index pages for boxes that previously had no operator page.

## Review

All eleven BMCs now have an extraction recipe. Local SquashFS probes passed for OpenBMC, NVIDIA OpenBMC, Supermicro X14, iDRAC9, and iDRAC10 at the documented offsets. The recipes leave boot artifacts unchanged; Lenovo XCC and Fujitsu iRMC remain explicitly format-discovery cases where the repository does not verify a generic offline root extraction.

# Complete partition-image extraction

- [x] Add `tools/extract-image-filesystems` to discover and export every mountable filesystem from raw or qcow2 images.
- [x] Replace Lenovo and Fujitsu discovery-only page text with the runnable extractor.

## Review

The remaining partition-image cases now have an actionable command. The extractor is read-only, refuses to overwrite an existing output tree, and leaves unknown/swap/boot metadata packed. It requires `guestfish` from `libguestfs-tools`; syntax and documentation-pair checks pass locally, but the current macOS host lacks guestfish for a live image run.

# Embedded-region completeness correction

- [x] Document OpenBMC writable JFFS2 alongside its SquashFS root.
- [x] Document Advantech root, Web UI, both configuration copies, and DRE JFFS2.
- [x] Document both MegaRAC configuration JFFS2 copies and the X14 initramfs.

## Review

The per-box recipes now cover every filesystem region identified by the checked-in build and boot recipes. Partition images use the new read-only discovery extractor; embedded regions use their recorded offsets and native filesystem tools. No boot artifact is modified.

# Audit Lenovo XCC shell scripts

- [x] Recover and hash-verify every path in the 191-script manifest.
- [x] Review hardware, bus, recovery, service, provisioning, and vendor-helper scripts.
- [x] Flag sensitive capabilities, cold-boot relevance, IBM provenance, and unresolved behavior.
- [x] Publish a Tailwind HTML report with every manifest path represented exactly once.
- [x] Verify HTML parsing, catalog coverage, and repository whitespace.

## Review

The recovered archive contains exactly the 191 requested paths and has SHA-256 `35c631100b4b6b12a534bbfa8626fc143f15d52f42b2e7cdea58910dc0195425`. The report in `docs/lenovo-xcc-shell-script-findings.html` documents direct MDIO, I²C, FPGA/CIO, MMIO, VUART, NC-SI, IPMI, PCH-reset, firmware-recovery, state-erasure, diagnostic-export, forwarding, virtual-media, listener, and provisioning capabilities. It identifies five scripts with direct IBM copyright, separates broader IMM inheritance from authorship, and explicitly marks proprietary-binary and ambiguous-shell boundaries unresolved. Every catalog entry now explains its concrete mechanism, enabled capability, operational or security implications, dependencies, provenance, and evidence limits in at least three sentences. Static verification found all 191 unique manifest paths exactly once and exact text equality with the three independently reviewed expansion datasets; Python's HTML parser, the documentation sync check, and `git diff --check` pass.

The continuation handoff in `docs/lenovo-xcc-shell-script-handoff.html` preserves the post-catalog analysis: front-panel USB ownership, NMI and SMI paths, MySQL schemas and missing dumps, VGPIO framing, eMMC acquisition limits, FFDC push behavior, secure-erase acquisition targets, PFR/PCH recovery, evidence gaps, operator constraints, and prioritized next steps. It makes conversation compaction safe without treating static firmware as live device state.

The handoff also includes a narrow-screen layout: phone-sized typography and spacing, wrapped command/hash text, compact list indentation, and separated finding sections. HTML parsing, required mobile-style checks, and `git diff --check` pass.

# Deepen Lenovo XCC SMI/SMM analysis

- [x] Extract and hash a minimal binary evidence set from the preserved XCC 6.92 SquashFS.
- [x] Trace nonce authentication and KCS/SMM request and response paths.
- [x] Trace VGPIO/WHEA dispatch, data stores, and BIOS event definitions.
- [x] Trace FPGA SMI generation, SMI-pin reset, and SMM-less transport behavior.
- [x] Reconcile evidence into explicit send, receive, handle, data, and authorization conclusions.
- [x] Update and stamp both Tailwind HTML reports.
- [x] Validate report structure, evidence claims, repository checks, and commit the result.

## Review

Static analysis of the XCC 6.92 SquashFS now separates seven mechanisms that earlier shell-only evidence blurred together: diagnostic NMI, fixed RTC-sync SMI, the queued SMI device, nonce-authenticated KCS-SMM, the MPFA memory-fault doorbell plus OEM-IPMI records, VGPIO/WHEA event plumbing, and the unrelated chassis-PSoC protocol named SMMLESS. The report states direction, payload, trigger, authorization boundary, response behavior, and negative findings for each path.

The strongest proved CPU-SMM path is host-to-BMC: a 32-byte `secure_nonce` is split between TWR and a 16-byte KCS prefix, checked before a narrow NetFn/Cmd whitelist, then stripped before ordinary IPMI dispatch. The BMC returns ordinary KCS responses. The callbacks fail open if unregistered, but normal initialization registers them; no practical startup bypass, arbitrary SMI handler selection, arbitrary SMM execution, SMRAM access, unsolicited BMC-to-SMM payload channel, or network entry into KCS-SMM is established.

The VGPIO handler is registered at NetFn `0x2e`/Cmd `0x92` for two OEM IDs. It can operate only on configured logical mappings; `AssertWHEA` creates SEL/auxiliary-log state and an 18-byte v2 `GPIO` record in `whea-data`, while filtered CPU SELs produce 24-byte v1 `IBMC` records. This can synthesize telemetry, but no direct SMI or host acceptance is proved. MPFA uses a separate NetFn `0x3a`/Cmd `0xcd` record exchange plus a one-bit SMI doorbell. The SMMLESS path is instead BMC-to-chassis-PSoC I2C and has no demonstrated relationship to x86 SMM.

Earlier unsupported claims were corrected: `/dc/ibmc/nonce_flag` is absent from the evidence; offset `+0x5d` is not a proved nonce-required flag; `Kcs_SMM_RcvCallback` is a notification hook, not the payload receiver; and the v1 and v2 WHEA writers are separate classes. The detailed report retains all 191 catalog entries. Artifact UUIDs remain `485be802-d991-400d-9afe-e03e20a40760` for the full report and `c975c2aa-4408-4c9a-b03d-531949f7bb76` for the handoff.

Verification reparsed both reports and the generated task HTML, asserted the mobile viewport and Tailwind shell, found all required SMI/SMM sections, preserved exactly 191 catalog rows, rehashed every cited firmware/library artifact, passed `tests/sync-docs-cli.sh`, confirmed the documentation pair is synchronized, and passed `git diff --check`. The repository-wide `tests/run` instead stops in the unrelated existing `advantech-console-lifecycle.sh` test because BSD `sed` treats its temporary pathname as a command; no Lenovo-documentation assertion failed.
