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

# Resolve Lenovo MMIO, MDIO, and host-DMA boundaries

- [x] Trace `hub_reset.sh`, `memdump`, `peek`, and `poke` to their BMC `/dev/mem` mechanism.
- [x] Recover the XCC 4.30 MDIO sysfs handler and establish its exact Clause 22/45 scope.
- [x] Compare the retained scripts against the XCC 6.92 kernel and identify the removed endpoint.
- [x] Recover the disabled AST2600 X-DMA node, driver API, PCIe gates, and runtime dependencies.
- [x] Reconcile the Lenovo candidate with the proved Dell BCM5709 experiment and Supermicro X-DMA architecture.
- [x] Correct and expand both durable Lenovo reports.
- [x] Stamp, validate, and commit the report update.

## Review

`hub_reset.sh` is CPU-mediated BMC MMIO, not DMA, and 0x40800000 remains an unidentified vendor block. The actual Lenovo host-DMA candidate is the AST2600 X-DMA engine at 0x1e6e7000. Lenovo ships both hardware description and a complete kernel driver, but disables the DT node and omits its mandatory reserved-memory pool; live PCIe link, BusMaster, gate, and host-IOMMU state remain unproved.

The old MDIO wording was too broad. The recovered XCC 4.30 implementation targets a fixed PHY address per interface and reaches Clause 22 registers plus encoded Clause 45/MMD space through bit-banged MDC/MDIO. It cannot address MAC MMIO, descriptor rings, PCIe configuration/BARs, X-DMA, BMC RAM, or host RAM. XCC 6.92 still ships the shell wrappers but no longer contains their kernel endpoint.

The Dell comparison now follows the July 22 proof rather than the stale May 14 planning report. With VT-d disabled, the BCM5709 consumed a forged TX descriptor pointing at another process's physical page, internally looped those bytes into RX, and recovered the marker; a later 1 MiB run recovered real RAM. The later bulk dumper's RX-ring regression produced zero-filled chunks, but does not invalidate the single-shot arbitrary-physical-read proof. Dell commit `27f71aaaf` and the three source files under `/Volumes/yyy/phd/mobo/NIC/bcm5709/` are the durable implementation evidence.

Follow-up corrected an overclaim about `hub_reset.sh`: `/dev/mem` proves the BMC CPU issued the access, not what decoded it. The AST2600 A3 map leaves 0x40000000–0x4fffffff unassigned; AHBC8C does not remap that gap; Lenovo's DTB contains neither RAM nor a peripheral/PCIe window at 0x40800000. That makes a standard AST2600 host-memory window unlikely, but only real-hardware resource capture, fault behavior, state correlation, and ultimately a reserved host-page marker can distinguish stale/unmapped code from undocumented board logic or a hidden bridge.

The shipped `libmod_sysfw.so.0.0.0` also proves the path remains integrated: `bios_device::ipmi_usb_reset` maps request byte 0 to `/bin/hub_reset.sh -d`, byte 1 to `-h`, and rejects other values with 0xc9. The script ignores that argument, so both valid requests run the same disconnect/wait/reconnect sequence, and the caller performs no visible address-window setup. This narrows the software behavior without identifying the live hardware decoder or the external IPMI NetFn/command.

Verification reparsed the findings, handoff, and generated task HTML; compared all 191 catalog rows exactly against the acquisition manifest; asserted the Tailwind/mobile shell and the corrected X-DMA/MDIO/Dell claims; passed `tests/sync-docs-cli.sh`; and passed `git diff --check`. The report and handoff retain artifact UUIDs `485be802-d991-400d-9afe-e03e20a40760` and `c975c2aa-4408-4c9a-b03d-531949f7bb76`.

# Validate HD Moore's `fujitsu-irmc` box

- [x] Build commit `408ed06` on the Mac from the exact SHA-256-pinned iRMC S6 image.
- [x] Cold-boot the unmodified box and capture its real guest address and service state.
- [x] Correct only the test worktree's host-forward destination and repeat the cold boot.
- [x] Probe HTTPS, static UI assets, HTTP redirect, SSH, Redfish session creation, and RMCP+ IPMI.

## Review

The exact HD build completed under macOS/QEMU 11.0.0 and the firmware reached runlevel 3, serial login, `IPMIMain`, and `FTS_WebServer`. The published launcher is not turnkey: it forwards TCP/UDP services to `192.168.2.100`, while the emulated firmware uses DHCP and repeatedly receives `192.168.2.15`. It also records the transient `sudo/nohup` wrapper PID rather than QEMU's child PID, causing `status` and `stop` to report the VM down while it remains active. Finally, `ifconfig lo0 alias 10.0.6.70 up` creates a class-A `/8` alias on macOS, temporarily routing the entire lab `10.0.0.0/8` into loopback; the test corrected that alias to `/32` and verified ordinary routing again.

After changing only `GUEST_IP` to the observed `.15` in the detached test worktree, HTTPS became stable at approximately four minutes. Five consecutive checks returned HTTP 200 with the same 1,769-byte iRMC page; the server identified itself as `iRMC S6 Webserver`, advertised `v2.63a-S6M6_M7`, served every tested Angular/CSS/SVG asset including the 3.14 MB main bundle, and redirected HTTP to HTTPS. SSH is disabled by firmware and resets before key exchange. Redfish session creation returns HTTP 503. RMCP+ `mc info` times out even though `IPMIMain` starts; the console records `Failed firewall`. Thus HD proved a booting iRMC Web frontend in principle, but the committed launcher cannot reach it without correcting the guest target, and its claims of working IPMI and SSH are not borne out.

Follow-up isolated the RMCP failure independently of the host forward. The exact Debby firmware cold boot recovered an invalid `/conf` JFFS2 partition, generated fresh IPMI configuration, and started `IPMIMain`, `libipmilan`, and `LANIfcTask`, but `/proc/net/udp` contained no port 623 socket. The generated `/conf/BMC1/LanIfccfg.ini` marked management `eth0` as `Enabled=0` and `Up_Status=0`; more decisively, `/conf/BMC1/lan_kcs.ini` set `AMI_DYNAMIC_LAN_IFC_SUPPORT=0` while leaving dynamic KCS enabled. Ghidra showed `libipmilan::UpdateLANStateChange()` tests the corresponding `g_AMIBMCInfo[24]` byte before calling its UDP socket creator. Runtime memory confirmed `{dynamic LAN, dynamic KCS} = {0,1}`. `Failed firewall` is not causal: `IPMIMain` logs it and continues.

The causal test enabled only management `eth0`, set `AMI_DYNAMIC_LAN_IFC_SUPPORT=1`, removed the stale binary configuration cache from the load path, and restarted `IPMIMain` in a disposable snapshot. The runtime feature bytes became `{1,1}`, the guest immediately bound dual-stack UDP/623, and host-side `ipmitool -I lanplus` returned a valid Fujitsu IPMI 2.0 `mc info` response (manufacturer 10368, product `0x0666`). Editing `LanIfccfg.ini` alone was insufficient because `IPMIMain` restored `/tmp/BMC1/IPMIConfig.dat` over the text file. This explains both the original Debby timeout and why the earlier INI-only startup hook failed.
