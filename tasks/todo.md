# Goal: complete OEM IPMI documentation and zipmi coverage for the zoo

Work one firmware target at a time. A target is complete only when its command and selector
denominator, wire contracts, authorization/channel behavior, side effects, activation evidence,
zipmi implementation, focused tests, and safe live evidence are all accounted for. Unknowns are
work items, not silently treated as supported.

## Target 1 — Advantech ASMB-787

- [x] Establish the firmware-bound denominator: 187 declared remote vendor rows.
- [x] Map every handler to available vendor header request/response structures.
- [x] Decompile handlers without source contracts and recover their wire behavior.
- [x] Resolve selector/subcommand spaces, completion codes, side effects, and channel gates.
- [x] Prove plugin runtime registration or mark feature-absent rows with exact evidence.
- [x] Add structured zipmi request/response codecs for every unambiguous fixed-width wire contract.
- [x] Keep named raw execution only where schemas remain variable/union/ambiguous, with safety gates.
- [x] Add exhaustive source/catalog/codegen/codec tests.
- [x] Safely live-verify every synthesizable read-only codec against the exact ASMB-787 image.
- [x] Update and stamp the Tailwind HTML reference and fleet audit.
- [x] Run focused verification, review the diff, commit, and push; final aggregate verification follows the zBMC pin.

## Target 2 — Dell iDRAC10

- [x] Pin the exact 1.30.10.50 firmware artifacts, module hashes, and provenance UUIDs.
- [x] Reconcile the prior operation catalog, 383 dispatch triples, 346 apparent dispatch pairs, and
      445-row historical live sweep into one explicit denominator model.
- [x] Resolve the formerly undetermined operation as NetFn 0x06 / command 0x33.
- [x] Prove handler activation, transport/channel reachability, privilege, and in-band-only gates.
- [x] Recover every selector/subcommand, request/response layout, completion code, side effect, and
      safety tier, retaining bounded unknown helper payloads without guessing.
- [x] Add vendor-scoped zipmi exact-operation contracts and structured codecs for every unambiguous
      fixed-width layout; preserve safety-gated named raw execution for variable/union formats.
- [x] Import historical live evidence with exact identity matching, then safely revalidate every
      synthesizable read-only contract against the pinned image.
- [x] Update the Tailwind HTML reference, fleet audit, PhD area landing/bibliography/tools, and stamps.
- [x] Run source/codegen/codec/CLI tests, full unit and baseline-diff verification, release/version
      proof, zBMC pin/install proof, review, commit, and push.

## Review — Dell iDRAC10

Dell YP95X 1.30.10.50-A00 is registered as immutable artifact
`50be7104-c060-5e24-b3d8-f8db4fdbbb13` (SHA-256
`372c49cf8fc167aaff0acc03925a782698937bddba21cbca57146a7c8d722ca9`). The exact
rootfs and dispatch-library hashes are pinned in the command source; Dell bibliography/tools docs
are stamped in PhD commits `f3258e62341b90f9ddd65d030f7f184a7fe8a27e` and
`16d19898dd825bfc7c4545be324832cba3475c17`.

The final denominator is 429 physical dispatch rows, 383 unique netfn/command/handler triples,
346 apparent pairs, 255 Dell-relevant remote top-level pairs, and 581 selector-expanded operation
identities. Every record has evidence. The 69 remaining opaque helper/SCBMC contracts are bounded
unknowns and remain unsafe; they are not missing denominator entries. zipmi 0.4.0 exposes all 581
operations with contract-gated named execution, 20 exact request codecs, and 130 exact response
codecs. The fresh Debby run exercised all 13 strictly synthesizable zero-body safe reads: 11 returned
CC00 and two returned target completion codes, with no transport failure. Release commit
`6dede85cc33ca5f9a035915b05e21df4c6c2e872` is the zBMC installer pin. The pushed installer was
streamed to isolated Debby venv `/home/zen/zipmi-0.4.0-proof.3zHo1x/venv`; `zipmi.__version__`,
package metadata, and `zipmi -V` all reported 0.4.0, and its marker recorded the exact release commit.

## Remaining target order

1. Lenovo XCC
2. Fujitsu iRMC
3. Dell iDRAC9
4. HPE MegaRAC / XD670
5. Supermicro X14
6. NVIDIA OpenBMC
7. Supermicro X10
8. IEIT
9. OpenBMC baseline

The order favors bounded firmware inventories first; it may change only when evidence shows a target
depends on work owned by a later shared platform catalog.

# OEM IPMI reference and fleet coverage audit

- [x] Recover the original request and inventory all 11 registered BMCs.
- [x] Compare target documentation with zipmi catalogs, named dispatch, and registered codecs.
- [x] Record firmware applicability, conflicting references, and counting limitations in the HTML audit.
- [x] Finish the corrected ASMB-787 command-by-command evidence reference.
- [x] Complete and verify the target-specific zipmi named raw dispatch catalog.
- [x] Validate the audit artifact and documentation links.

## Review

ASMB-787 is complete for its exact firmware-bound remote OEM surface. All 187 dispatch pairs have
462 handler-proven selector operations with request/response lengths, selectors, completion codes,
safety tiers, side effects, activation evidence, and binary hashes. zipmi 0.3.4 exposes every pair,
generates 81 unambiguous fixed-width codecs, and retains exact raw contracts for variable, union, or
ambiguous formats. The fresh post-reboot run exercised all 32 safely synthesizable read-only codecs:
26 returned CC00 and six returned expected target completion codes, with no transport failures.
The ASMB completion proof used release commit `45191509417a14e1f823b188cdb3721e7e4ad13f`;
the installer has since advanced to the iDRAC10-complete zipmi 0.4.0 release.
Focused Advantech lifecycle, documentation contract, documentation sync, shell syntax, and clean
zipmi-install/version checks pass. The aggregate shell suite passes before and after the unchanged
local `ilo5-gxp-umac.sh` boundary; that one baseline test exits 127 because the untracked local
Renode runtime is absent. No ASMB or zipmi regression is hidden by that environment-only gap.

The source-linked report is [OEM IPMI coverage audit](../docs/oem-ipmi-coverage-audit.md).
ASMB-787 and iDRAC10 are now certified for their pinned firmware images as fully
denominator-accounted, documented, and covered by native zipmi named execution. The ASMB reference
covers 187 declared remote pairs and 462 selector-expanded operations with 81 fixed-width codecs.
The iDRAC10 reference covers 255 Dell-relevant remote pairs and 581 selector-expanded operations
with 20 request and 130 response codecs. Remaining raw-exact entries on both targets are explicit
variable, union, delegated, or bounded-opaque contracts—not uncounted commands.

Verification: isolated offline imports measured registry names and request/response codec classes.
The report contains exactly all 11 tracked box descriptors, and every local source link resolves,
including sibling zipmi links. The changed documentation pairs and the existing `tasks/lessons.md`
source are regenerated and synchronized; targeted documentation and whitespace checks pass.

# Complete Advantech ASMB-787 six-service acceptance

- [x] Reopen acceptance: require ICMP, console, IPMI, Redfish, SSH, and authenticated Web UI.
- [x] Trace the SSH post-authentication hang to its owning firmware state or shell.
- [x] Trace the Web UI login/dashboard path and distinguish slow response from broken authentication.
- [x] Implement the minimum root-cause fixes and six-service health probes.
- [x] Cold-boot and prove all six services through `zbmc status -v`.
- [x] Audit whether the firmware's complete OEM IPMI surface is documented.
- [x] Update the HTML-authored GitHub page, regenerate its Markdown mirror, push, and verify publication.
- [x] Run the complete verification suite and record the review evidence.

## Review

The SSH failure was post-authentication routing, not OpenSSH or PAM. `/etc/passwd` links to
`/conf/passwd`; `sysadmin` used `/usr/local/bin/defshell`, which routed SSH sessions to SMASH, where
that account has no privilege. The runtime image now changes only `sysadmin` to `/bin/sh`. Exact-marker
remote-command and forced-PTY checks both reached the BusyBox shell as UID 0.

The MegaRAC Web UI was functional but absent from the acceptance contract. Its health probe now creates
an authenticated session, requires both the CSRF token and `QSESSIONID`, reads the protected
administrator dashboard resource, and deletes the session. IPMI and protected Redfish remain
authenticated functional probes.

Debby cold run `20260925T214443Z-ce946490-918d-40af-83be-b2957f51c753` reached
`READY [6/6 - ICMP, SSH, IPMI, Redfish, Web-UI, Console]` in 672 seconds. Follow-up proof returned
`uid=0(sysadmin)` for non-PTY SSH, forced-PTY SSH, and the serial console; OEM query NetFn `0x32`, Cmd
`0x90` returned `01`.

The corrected OEM documentation audit found 187 declared remote vendor rows: 180 unique NetFn `0x32`
entries (85 core plus 95 across 37 loadable AMI modules), five NetFn `0x30` platform commands, and two
NetFn `0x3a` platform commands. Existing material documents the YAFU block and selected sensitive
handlers. The completed evidence reference now covers every row: 92 core/platform rows are statically
registered; 85 plugin rows are feature-enabled or eligible without direct proof of runtime map
population; and ten Media, PLDM, and Remote KVM plugin rows are feature-absent and remain unproved.
Three additional NetFn `0x2e` SMM-local PDK records remain outside the remote denominator pending
transport proof. zipmi exposes all 187 remote rows through its target-specific named raw dispatch
catalog while preserving unknown payload fields and the absence of structured codecs.

The focused Advantech lifecycle test, all 57 documentation pairs, documentation link contract,
sync-docs CLI test, and `git diff --check` pass. The aggregate local suite passed through
`ilo5-gxp-scan.sh`, then stopped at `ilo5-gxp-umac.sh` because this Mac checkout lacks the untracked
Renode runtime; that UMAC test passed separately on Debby with Renode 1.16.1. Every test after the
UMAC boundary passed locally.

GitHub publication was verified through GitHub's read-only API after pushing `main`: the published
README rendering contained the exact six-service READY string, the published Advantech page contained
the then-current OEM audit, and the remote `main` SHA matched the local commit. The command count and
field labels were subsequently corrected in the OEM audit work above.

# Restore managed IPMI on Advantech ASMB-787

- [x] Recover the interrupted session and identify the live BMC and exact failing boundary.
- [x] Prove ICMP, HTTPS, Redfish ServiceRoot, and authenticated RMCP+ independently.
- [x] Correct process discovery, credentials, and the declared IPMI readiness contract.
- [x] Clear the firmware first-login gate through its supported password-change path.
- [x] Cold-start under zBMC management and verify status, IPMI, and a non-destructive OEM command.
- [x] Run focused/full checks, record review evidence, and commit the result.

## Review

The ASMB-787 was already answering ICMP and completing RMCP+ sessions with the firmware's initial
`admin/admin` credential. The apparent IPMI failure had two causes: the box descriptor still used
`admin/superuser`, and MegaRAC's `PasswordChangedAtFirstLogin` gate returned completion code `0x18`
before dispatching ordinary user-management and OEM commands. The box now uses its existing
post-launch hook to perform the standard IPMI Set User Password operation for user 2, establishing
the documented `admin/superuser` lab credential without patching the vendor dispatcher.

Debby cold run `20260925T180428Z-f7448097-e616-4bde-9173-14d0cfe3a631` reached managed READY in
529 seconds with ICMP, authenticated IPMI, and console required. The bootstrap log records the
successful standard password change; `zbmc advantech-asmb787 ipmi mc info` returned Advantech
manufacturer ID 10297/product `0x2000`; non-destructive OEM query NetFn `0x32`, Cmd `0x90` returned
`01` instead of `0x18`; and authenticated `/redfish/v1/Systems` returned HTTP 200. Redfish is now
part of the declared contract, while SSH and the interactive Web UI remain unaccepted.

The focused lifecycle test, all 57 documentation pairs, `git diff --check`, and every repository
test script passed. The local aggregate run lacked the untracked Renode runtime and stopped at the
UMAC script; that script passed separately on Debby with Renode 1.16.1, and every subsequent test
passed locally.

# Enable Fujitsu iRMC Linux SSH

- [x] Reconcile the older reset-before-key-exchange result with the current diagnostic shell hook.
- [x] Identify the vendor SSH service-state gate and its boot-time owner.
- [x] Enable only the vendor SSH service when the diagnostic shell is requested.
- [x] Cold-build and prove remote commands, PTY shell behavior, and preserved IPMI/Redfish/Web UI.
- [x] Update the service contract and documentation and run the full test suite.

## Review

The root cause was two independent vendor gates: <code>[ssh].current_state=0</code> prevented the
SysV service from starting, and the proprietary <code>sysadmin:j:</code> passwd marker prevented
<code>pam_unix</code> from consulting the preserved shadow hash. Initramfs version 23 changes only
those runtime values when <code>irmc_diag_shell</code> is requested, then bind-wraps the vendor SSH
init script. It also preserves command arguments through the existing <code>defshell → remman</code>
diagnostic-shell bind mount.

Debby cold run <code>20260925T054554Z-e12565e1-dd69-45ee-9eb1-09df9e97ea7c</code> reached READY in
25m30s with required SSH, IPMI, Redfish, and Web UI stable. The exact SSH marker passed at 5m51s;
an interactive PTY returned UID/GID 0 and <code>/root</code>. A final verbose status with the 120s
Fujitsu SSH probe budget passed 5/5 network services and reported the console available. Evidence is
retained under the run ID in the disposable Debby checkout.

# Restore IEIT Linux SSH while preserving vendor CLP

- [x] Recover the old authenticated SSH/SMASH evidence and readiness timings.
- [x] Trace sshd, PAM/NSS, account shells, and first-boot host-key generation.
- [x] Preserve `admin/admin` as the vendor SMASH/CLP login.
- [x] Enable the existing `sysadmin` account as the Linux SSH login.
- [x] Cold-build and prove remote commands, interactive shell, CLP, IPMI, Redfish, and Web UI.
- [x] Document, run the focused and full tests, commit, and push.

## Review

Old evidence and a fresh baseline cold boot prove that the preserved OpenSSH service accepts
`admin/admin` and launches the vendor `/usr/local/bin/smashclp`; the fresh scripted session reached
the `/smashclp>` prompt, ran `help`, and exited cleanly. Static analysis traced `admin` through the
IPMI NSS/PAM path and found the separate local UID-0 `sysadmin` account blocked by both
`DenyUsers sysadmin` and its console-selecting `defshell`.

The rebuilt configuration leaves `admin` and SMASH unchanged, changes only `sysadmin` to `/bin/sh`,
gives it the standard lab password, and removes the sshd deny rule. The box's SSH health probe
executes a remote command and requires an exact marker, while `zbmc ieit clp` continues to use the
vendor account.

Disposable Debby run `20260925T041721Z-00eb58d3-f570-437d-b666-60a716edfabe` cold-built the image
and reached READY for all five required network services at `10.250.0.41` in 124 seconds, with the
console available. Remote-command and forced-PTY sessions both returned `uid=0(sysadmin)`, `/bin/sh`,
and the requested markers; the separate `admin` session
reached `/smashclp>`, ran `help`, and exited. Authenticated IPMI returned product `0x0202`, Redfish
reported version 1.8.0, and the Web UI returned HTTP 200. The stopped run is preserved under
`/home/zen/src/oob/zbmc/work/ieit/runs/` on Debby. The focused checks and the complete Linux
`tests/run` suite pass, including all 57 documentation pairs.

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

# Enable Fujitsu iRMC IPMI on cold boot

- [x] Reproduce the missing UDP/623 listener on Debby after its reboot.
- [x] Add the proven LAN feature, management-channel, and cache-invalidation changes before `IPMIMain`.
- [x] Rebuild the derived initramfs and verify its injected startup hook.
- [x] Cold-boot on Debby and verify guest configuration, UDP/623, authenticated IPMI, and HTTPS.
- [x] Update operator documentation and commit the verified fix.

## Review

The cold-boot hook runs immediately before `IPMIMain`. It creates the two observed default INIs only when absent, enables only management `eth0`, enables dynamic LAN support, and removes the stale binary shadow cache. This is confined to the derived initramfs and snapshot-backed runtime; the five SHA-256-pinned vendor inputs remain unchanged. The packed version-17 initramfs on Debby has SHA-256 `91fa8f3beb7412792fcd7862d4a976c242978d274331744d418f89d6ee406594` and contains the management-channel, dynamic-LAN, and cache-invalidation operations.

Debby run `20260924T060412Z-7a079809-e09d-44c5-8066-fddc2c54f560` reached managed READY in 532 seconds. The guest retained `Enabled=1` and `Up_Status=1` for `eth0`, both dynamic interface flags were `1`, `/proc/net/udp6` exposed wildcard port `0x026f`, and `IPMIMain` ran as PID 305. Authenticated `mc info` returned manufacturer 10368 and product `0x0666`; five serialized follow-up HTTPS probes all returned HTTP 200, followed by another successful IPMI query.

The same run also proved the old bootstrap matcher was fragile: firmware diagnostics split `INIT: Entering runlevel: 3`, so readiness never began probing services. Matching the stable substring `Entering runlevel: 3` allowed the supervisor to record BOOTSTRAP, IPMI, Web-UI, stability, and READY normally. The focused iRMC test, documentation-pair test, pair synchronization check, and `git diff --check` pass. The repository-wide `tests/run` still stops at the pre-existing macOS `sed` failure in `advantech-console-lifecycle.sh`; it fails before reaching any iRMC test.

# Revalidate iRMC bidirectional connectivity with retained tooling

- [x] Use `tools/zbmc irmc-fujitsu status -v` for Debby-to-BMC ICMP, authenticated IPMI, and HTTPS.
- [x] Reuse the retained serial command runner for BMC-originated ICMP tests.
- [x] Preserve the command and evidence under `/home/zen/xcc-shell-audit-20260922/` and the managed run log.

## Review

The existing zBMC status probe reports the live iRMC run READY with ICMP, authenticated RMCP+ IPMI, and HTTP 200 HTTPS responses from Debby. The retained serial command runner then submitted one marked command through the existing QEMU serial socket; the managed console log records three replies from Debby (`10.0.0.24`) and three from the Mac (`10.0.0.2`), with 0% loss in both directions. The first runner stopped after QEMU recorded the result because its socket-only completion capture was not suitable for this noisy logfile-backed chardev; the later reusable runner supports the logfile explicitly while continuing to drain the socket.

The lower transport layer was then tested independently of credentials and application content. An unauthenticated Nmap `ipmi-version` probe found UDP/623 open as ASF/RMCP and received an IPMI 2.0 capability response. Plain TCP handshakes from Debby succeeded on BMC ports 80, 443, and 623; ports 22, 23, 664, and 8443 actively refused instead of timing out. In the reverse direction, the BMC's existing BusyBox `wget` connected to a temporary Python standard-library listener on Debby port 45690, fetched `network-test.txt` with exit status zero, and produced an HTTP 200 log entry sourced from `10.250.0.42`. Thus basic ICMP, UDP/RMCP, and bidirectional TCP connectivity are proved before authenticated IPMI or Web-UI health is considered.

# Preserve reusable BMC connectivity tools

- [x] Save the host-side ICMP, TCP, and unauthenticated RMCP probe.
- [x] Save the reverse HTTP listener and guest-command generator.
- [x] Consolidate serial command delivery and capture into one generic runner.
- [x] Add socket and logfile-mode regression coverage.
- [x] Validate both directions against the live Fujitsu iRMC.

## Review

`tools/zbmc-connectivity` now provides `probe`, `serve`, and `guest-command` operations without embedding credentials. `tools/zbmc-serial-capture` sends a saved command through any QEMU Unix serial socket, optionally paces bytes, captures directly from the socket or follows QEMU's serial logfile, and waits for an exact marker line so an echoed command cannot produce a false success. In logfile mode it still drains the socket, because live validation proved that leaving the socket unread can fill QEMU's chardev buffer and stall guest console output.

The regression test exercises generated guest commands, exact-line marker handling, direct socket capture, and logfile capture under enough simulated firmware noise to fill a socket buffer. Live validation on Debby repeated the full host-side probe successfully, then used only the saved tools to make the iRMC ping Debby and fetch `zbmc-connectivity.txt` over TCP. The iRMC reported three of three ICMP replies and `wget_status=0`; Debby's listener logged HTTP 200 from `10.250.0.42`.

# Trace Fujitsu iRMC IPMI listener and response sources

- [x] Bound UDP/623 availability from the retained cold-run packet capture and event timeline.
- [x] Prove the live socket owner, threads, file descriptors, and queue endpoints.
- [x] Trace RMCP/RMCP+ receive, message dispatch, and response framing through the vendor libraries.
- [x] Map representative successful commands to cached state, files, network helpers, callbacks, IPC, and device boundaries.
- [x] Record unresolved physical backends and directly bound the listener appearance time without overclaiming.
- [x] Publish and verify a durable Tailwind HTML report and generated Markdown pair.

## Review

The first retained run proves that `IPMIMain` existed by guest uptime 51.852 seconds, unanswered Open Session probes continued through elapsed 218.807 seconds, and the first RMCP+ Open Session Response was captured at elapsed 451.541 seconds. Authenticated IPMI completed at 490 seconds and managed READY followed at 532 seconds. A later instrumented cold boot sampled `/proc/net/udp6` and `/proc/net/tcp6` every 100 ms: both port-623 sockets were absent at guest uptime 41.75 seconds and first appeared together at 106.99 seconds, but firmware network reconfiguration repeatedly closed and recreated them. The final stable pair appeared at 484.42 seconds and the run reached authenticated IPMI/Web readiness at 619 seconds. The vendor `ipmistack restart` experiment crashed `IPMIMain` and required a cold reboot, so it is not a safe tracing mechanism.

Live `/proc` evidence ties wildcard UDP/623 inode 20142 to PID 304 fd 52. The same process contains `RecvLANPkt`, `LANIfcTask`, `LANMonitor`, `LANTimer`, and eight `MsgHndlr` threads. Static analysis proves the route: `recvfrom` → `/var/LANIfcQ` → `ProcessRMCPReq` → `/var/MsgHndlrQ` → privilege/command-table dispatch → `/var/LANResQ` → RMCP+ framing → `sendto`. The queue names are IPC endpoints inside the multi-threaded process, not evidence of a second IPMI daemon.

Response sources are command-specific. Fujitsu overrides generic Get Device ID with `OEM_FTS_GetDeviceID`: the device byte comes from `system.conf`, the product bytes from OEM SDR subtype `0x22`, and the remaining bytes are constants. Channel and user replies read locked objects initialized from AMI configuration files; LAN replies combine those objects with live kernel-network helpers; SEL and SDR read in-process repositories backed by persistent/NVR files; chassis status mixes cached bytes with platform callbacks; and FRU delegates to a platform callback whose Fujitsu physical backend remains unresolved. `IPMIMain` has live I2C, KCS, GPIO, IPMB-queue, `/dev/mem`, reset, netmon, and misc-control handles, but the report does not attribute cached responses to those devices merely because the descriptors exist.

The new `boxes/irmc-fujitsu/ipmi-path.html` report contains the full timing, call chain, response-source table, confidence limits, evidence locations, and SHA-256 hashes. `tools/sync-docs --write` produced its Markdown pair and refreshed the Fujitsu overview pair.

# Restore Fujitsu iRMC Redfish

- [x] Reproduce and root-cause the delayed `FwInfo2` kernel panic.
- [x] Prove the AMI FMH parser initializes `ractrends_mtd[]` on a 128 MiB two-FMC view.
- [x] Preserve the fixed `platform`/SDR partition view alongside the FMH parser view.
- [x] Boot a disposable networked VM and validate authenticated Redfish without touching the known-good VM.
- [x] Hold beyond the former 804-second panic boundary and capture provenance.
- [x] Integrate the minimum verified boot changes, document, test, and review.

## Make the management address static

- [x] Identify the vendor source of truth and distinguish LAN object 0 from IPMI channel 2.
- [x] Configure `lancfg0.ini` with static IPv4, `/8` mask, and gateway before `IPMIMain` loads it.
- [x] Remove the host-side serial address reassertion.
- [x] Cold boot on Debby and prove neither IPv4 nor IPv6 DHCP starts, stable IPMI/Redfish/Web, and survival past delayed LAN restart.
- [x] Update the Fujitsu report, stamp/sync artifacts, run focused checks, and commit.

## Review

The version-21 derived initramfs configures Fujitsu LAN object 0 before <code>IPMIMain</code> starts: static IPv4 <code>10.250.0.143/8</code>, gateway <code>10.0.0.1</code>, IPv4 enabled, and IPv6 disabled. The vendor generated a static-only <code>/conf/interfaces</code>. The address and authenticated IPMI survived the initial and delayed LAN reloads without a host-side repair process.

The all-DHCP capture covered UDP 67/68 and 546/547 from cold boot through Redfish readiness and contained no packet records. At guest uptime 1782.40, neither DHCP client nor PID file existed. Redfish completed 274/274 resources, ServiceRoot returned HTTP 200 with <code>RedfishVersion</code>, unauthenticated Managers returned 401, authenticated Managers reached the expected 403 <code>PasswordChangeRequired</code> boundary, the Web UI returned 200, and authenticated RMCP+ still returned Fujitsu manufacturer 10368/product <code>0x0666</code>.

## Trace Redfish resource provenance

- [x] Separate definition JSON, generated instance JSON, backend mapping, IPC, producer process, and final device/file source.
- [x] Map resources 161–165 statically, including DIMM local-IPMI/Redis paths and NetworkInterfaces through `FTS_LAN_Cache`.
- [x] Preserve failed v4–v6 consoles; prove late boot sweeps `/tmp` and `/var/tmp`, reject read-only `/home`, and move v7 evidence to stable `/dev` devtmpfs.
- [x] Capture and hash a valid syscall trace through ResourceTree entry 165.
- [x] Correlate files, Unix sockets, SysV messages, waits, and exact DIMM request counts with resource timestamps.
- [x] Update the durable HTML report with the trace and live process/socket ownership evidence.
- [x] Stamp the report, register the new immutable ownership capture, and run focused verification.

## Review

The valid EABI5 trace covers the tail of entry 162 through entry 170. For entry 163 it records 40 reads of `MemoryMetrics_def.json`, 40 generated `Metrics_inst.json` files, and 280 successful Redis connections—seven per DIMM—over 119.881 seconds. Entry 164 then takes 2.675 seconds, contacts local IPMI four times, and writes an empty `MemoryDomains_inst.json`. Entry 165 advances in 0.239 seconds without contacting `lancache.sock`; the static LAN-cache path therefore remains capability evidence rather than a runtime attribution for this empty collection.

A fresh live `/proc` capture proves endpoint ownership in the same v7 VM: PID 2120 `FTS_RedfishServ` owns `RedfishServer.sock`, PID 294 `redis-server` owns `redis.sock`, PID 1922 `FTS_LAN_Cache` owns `lancache.sock`, PID 3836 `IPMIMain` owns `UDSocket1`, PID 2047 `FTS_RedfishTaskMngr` owns the task socket, and PID 2170 is the HTTP front end. The report now separates static definitions, generated output, immediate IPC source, producer process, and ultimate hardware/file source.

Static analysis shows that entries 162 and 163 share `NEXT_SYSTEM|NEXT_MEMORY`; `DMItemNextHandler_Memory` obtains maximum DIMM index and each module status through local IPMI on `/var/UDSocket1`. Maximum index 40 causes exactly forty status requests for indices 0–39. Most failures map to status 7, while the enumerator excludes only status 9, so missing emulated inventory causes forty unknown DIMM and metrics instances rather than an empty collection.

The runtime trace closes the former ambiguity: despite their `onDemand` declarations, the seven metrics callbacks are resolved while each initial instance is materialized. Forty DIMMs produce exactly 280 Redis connections and forty output files. The apparent 21-second MemoryDomains interval was a log-semantics error: “entry processed” is emitted before that entry's work. In the traced run, metrics takes 119.881 seconds and MemoryDomains itself takes 2.675 seconds.

The complete rotated log proves all 274 ResourceTree entries completed and the DataModel became responsive after 17m56s. Earlier status checks falsely reported a stall because they read only the new post-rotation log. The valid trace and current live process/socket ownership capture are retained under `work/irmc-redfish-integration/`; earlier files named as strace/ftrace captures contained no syscall records and are not evidence.

# Resolve field-level provenance for iRMC IPMI replies

- [x] Correct Get Device ID to the Fujitsu OEM handler selected at runtime.
- [x] Map each observed Device ID, chassis, channel, LAN, user, and SEL field to its exact handler expression and backing source.
- [x] Distinguish direct proof, configuration provenance, runtime kernel/device input, and unresolved callback boundaries.
- [x] Cite retained binaries, decompilations, live captures, paths, hashes, and symbol/offset evidence in the report.
- [x] Regenerate the Markdown pair, verify the focused runtime/docs checks, and commit the correction.

## Review

The report now traces every retained Device ID, chassis, channel, LAN, user, and SEL response field to the selected runtime handler, the exact expression or copy offset, and its constant, file, mutable object, repository, helper, callback, or device backing. It labels ELF and Ghidra addresses separately and records unresolved loader, event-producer, kernel-driver, and physical-signal boundaries instead of inferring them. A final `libnetwork` pass closed the LAN-helper boundary: interface values come from socket ioctls, the default gateway from `/proc/net/route`, and gateway MAC from `/proc/net/arp` or an active Layer-2 ARP exchange.

Fresh live evidence includes raw replies, guest configuration, the complete 25,952-byte SDR repository, and the complete 100 ms listener trace through READY. Static evidence includes named decompilations for the OEM Device ID, channel, chassis, LAN, user, SEL, socket, and network-helper paths. The report records paths, artifact UUIDs where registered, and SHA-256 hashes for each retained artifact. The focused runtime test was updated for the opt-in listener tracer and passes; HTMLParser, Pandoc, `git diff --check`, and the documentation-sync CLI test also pass. `tools/sync-docs --write` reported all 55 documentation pairs synchronized before its two unrelated ignored Lenovo Markdown byproducts were removed.

# Map Fujitsu iRMC OEM power commands

- [x] Recover every Fujitsu OEM dispatch table and decode actual wire NetFn, command, LUN, and selector fields.
- [x] Identify every power-control, power-policy, power-cap, PSU, energy, thermal-power, NMI, reset, and Node Manager operation.
- [x] Trace each power handler to its final cache, file, GPIO, miscctrl, I2C/IPMB, PSU, or other device boundary.
- [x] Map LAN, KCS1–3, UDS, IPMB, and internal reachability plus privilege/channel masks without issuing state-changing commands.
- [x] Publish and verify a durable power-first OEM command matrix with evidence paths, hashes, and explicit unknowns.

## Review

The power-first report at `boxes/irmc-fujitsu/oem-power-map.html` covers all 160 recovered Fujitsu table records (148 active, 135 distinct wire NetFn/command pairs), with detailed treatment of standard Chassis Control, User-level SCCI power selectors, Admin C0/D0 policy/watchdog/history controls, the complete 15-entry DCMI table, constrained raw PECI, Node Manager/IPMB, PSU PMBus, and cached telemetry. It distinguishes registration, transport reachability, handler execution, queued acceptance, and final physical actuation.

The final BMC-side paths are now concrete. Ordinary on/off is a 100 ms front-panel-button pulse through `/dev/miscctrl` to AST2600 LPC/SWC physical `0x1e789184` bit 15; power-good is `0x1e789180` bit 30; emergency off uses `0x1e789188` bits 12–14. Reset disables SCU passthrough and pulses AST GPIO index `0x79`. NMI traverses Chassis Control selector 4, the asynchronous power engine, and the RX2540 M7 product table to active-low AST GPIO index `0x69` through `socPulseGPIO`. The final motherboard nets and GPIO-HAL NMI pulse width remain explicitly unresolved. Fujitsu's exported SMI handler is a no-op; LPCSMI pinmux presence does not establish an SMI actuator.

The unconditional PCH-off path writes `0x0200` over I2C using runtime bus/slave fields. A read-only live memory capture followed the relocated platform-object pointer and recovered QEMU values `ff 00`, showing that backend is unconfigured in this emulation while leaving real-hardware bus/address unresolved. PMBus helpers directly open `/dev/i2c-N`, whereas ordinary IPMI wattage and history replies frequently use caches and ring buffers.

Transport proof is deliberately qualified. Four safe SCCI reads succeeded over authenticated LAN LUN0, including one in a session capped at User privilege. LAN LUN3 transported but returned `0xc0`. Three live KCS devices/listener threads preserve NetFn/LUN and enter shared dispatch, but QEMU lacks the host LPC/eSPI master and the final command-firewall channel-object index was not captured. UDS and IPMB software routes exist; neither physical peer path was exercised.

Static review identified security-relevant validation weaknesses without invoking them: User-level SCCI setters lack full length checks; D0 policy mode 4 uses an apparently unbounded request byte as an index for four runtime-array writes; D0 command `0x2c` copies 20 bytes from an undersized request and mutates counter state despite its getter name. NetFn `0x30` command `0x9b` is a no-op success stub, while `0xe6` provides a host-on-gated, command-allowlisted PECI multiple-write/read primitive rather than arbitrary PECI or host-memory access.

No state-changing power, reset, NMI, SMI, policy, inhibit, scheduling, watchdog, cap, fan, LED, PECI, or restore-policy command was sent. HTML parsing, focused report assertions, documentation-pair synchronization, the iRMC runtime test, repository whitespace checks, artifact stamping/sweep, live read-only SCCI queries, live process/queue capture, and static decompilation all pass. The repository-wide documentation contract still returns 1 for its pre-existing `README.html` links to eleven `.md` box indexes; none involves the new report links. The durable report UUID is `9071144c-5b3a-4c74-8f30-3a8331e244ec`.

# Reproduce the iRMC Redfish kernel panic in isolation

- [x] Preserve the known-good iRMC instance and launch a separate snapshot-backed VM with unique TAPs and no `irmc_no_redfish` argument.
- [x] Capture vendor Redfish task-manager and service startup, live process/thread wait channels, and the terminal kernel fault.
- [x] Preserve the full console evidence and remove only the disposable VM's TAP interfaces.
- [x] Correct the Fujitsu overview with the delayed failure timing and exact read/backtrace path.

## Review

The disposable run used the same pinned kernel, DTB, initramfs, 64 MiB flash image, and SD rootfs as the working instance. Its sole material service difference was omitting `irmc_no_redfish`; QEMU drives remained in snapshot mode and the working `10.250.0.42` instance was untouched. `FTS_RedfishTaskMngr` started first, followed by the unmodified `FTS_RedfishService`. The service created `/var/tmp/RedfishServer.sock` and remained alive for minutes: PID 2113 had six threads, its main thread waited in `epoll_wait()`, and two `RedfishInitThre` workers waited in `poll_schedule_timeout`.

At guest uptime 804.782 seconds, service thread PID 2116 faulted at virtual address `0x10`. The kernel identifies the PC as `fwinfo2_read+0x9c/0x238 [helper]` and records the complete read path from `sys_read` through `proc_reg_read`; the fatal exception then panicked the guest. This proves the delayed `FwInfo2` attribution under the single-FMC topology and also explains why a short health check can falsely suggest that restored Redfish is stable. The complete retained console is `work/irmc-redfish-repro/console.log`, SHA-256 `9ae9ca9cf9030388ed1a4a8ba863c6b0a586ab6da6a766fde5dbd612a6d0d1f4`. The disposable QEMU process exited after the panic and `ztap-rf0`, `ztap-rf1`, and `ztap-rf2` were removed.

# Run the full post-Redfish regression suite

- [x] Run every repository shell test on the supported x86_64 Linux host with the pinned Renode and Pandoc runtimes.
- [x] Fix failures exposed by the complete run and restart the suite from the beginning.
- [x] Recheck the retained Fujitsu VM's IPMI, Redfish, Web UI, resource completion, and static network evidence.

## Review

All `tests/*.sh` passed from a clean, isolated checkout on Debby. The run used the repository-pinned Renode 1.16.1 runtime and Pandoc 3.7.0.2. It exposed and corrected three unrelated stale test assumptions: BSD/GNU `sed -i` portability in the Advantech network helper, missing no-op probe-lock hooks in the isolated QEMU reroll fixture, and Lenovo's obsolete `BROKEN` warm-start expectation after matched TAP checkpoints became supported. The documentation contract also now has all 57 generated pairs and the canonical HTML README links to canonical HTML box pages.

The retained Fujitsu acceptance VM remains live at `10.250.0.143`. Authenticated IPMI returns manufacturer `10368` and product `0x0666`; the Web UI and Redfish ServiceRoot return HTTP 200; ServiceRoot reports Redfish 1.15.0; unauthenticated Managers returns 401; authenticated Managers returns the expected 403 `PasswordChangeRequired`. Its log still proves `274/274` and `DM initialized and responsive`. The retained all-boot DHCPv4/v6 capture is a 24-byte empty pcap with SHA-256 `704e5e5b3234433c01fcfd1b20a306e77e985038120492dc53965c3edd38a4ea`.
