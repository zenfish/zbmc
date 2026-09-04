# Fix GitHub contract workflow

- [x] Inspect the original and follow-up GitHub Actions logs.
- [x] Reproduce the new iLO5 contract locally.
- [x] Replace Ubuntu's incompatible `Cryptodome` package with an isolated PyPI `Crypto` environment.
- [x] Add targeted `.md` / `.html` arguments to `tools/sync-docs`.
- [x] Cover single-file, generated-file, and multiple-file selection.
- [x] Verify focused and full contract suites and inspect the final diff.

## Review

The original GitHub run failed because the new iLO5 contract requires `Crypto.Cipher.AES`, while the clean runner lacked that module. Two follow-up runs proved Ubuntu's `python3-pycryptodome` package was installed and its Python selected, but Debian-family packaging exposes `Cryptodome`, not the upstream toolbox's `Crypto` namespace. CI now creates an isolated venv with pinned PyPI `pycryptodome` 3.23.0, and the iLO5 reproduction guide uses the same dependency boundary.

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

- [x] Recover the prior Debby runtime state and verify saved svcsILO dumps.
- [x] Replace the incorrect physical-dump address model with the proven virtual image.
- [x] Trace the `0x12070` path through both `memset` calls to synchronous config IPC.
- [x] Prove a svcsILO-scoped default-config fastpath advances the former deadlock.
- [ ] Localize the next wait after the final default-config request and obtain guest network readiness.

## Review

The live Debby run in `work/ilo5-debby-attempt-139/renode.log` proved the tracked `gxp_dev.py` fix is on-path and changes behavior in the previously blocked svcsILO startup region. Before the fix, repeated control-register reads after event-service init returned `0x0`; with the fix, the same run shows persisted read-backs like `off=0xb0 -> 0x808`, `off=0xc4 -> 0x704`, and `off=0xa0 -> 0x101` before the guest clears them.

That run also reaches `SVCSILO_MAIN`, crosses `phase=after-event-service-init`, and continues to later `ILOMAIN_COMMAND` handling. This verifies the narrowest correct change in the device model: preserve non-mailbox register writes so later firmware reads can observe guest-programmed state.

Attempt 142 recovered the authoritative 151,552-byte virtual dump from attempt 126 and proved the previous `ALLOC30`/`REQ19` hook labels came from treating non-contiguous physical pages as a linear virtual image. Corrected hooks show both zeroing calls return; the actual block is the shared `0x01882918` wrapper, which builds syscall descriptor `0x98` and waits in SVC 0 for an absent config backend.

A fingerprint-scoped runtime fastpath now returns transport success while retaining each caller's pre-zeroed response buffer as factory/default configuration. The live run advances through nine requests, including OEM property get/set and command 2/3 state traffic. It has not reached the later `0x11e50` milestone, and `10.0.2.15` still does not answer ARP or ports 22/23/80/443, so no tracked fastpath patch is ready to commit yet. Evidence is preserved on Debby in `work/ilo5-debby-attempt-142/renode.sync-config-block.log`, `renode.oem-fastpath-next-block.log`, and the current `renode.log`.
