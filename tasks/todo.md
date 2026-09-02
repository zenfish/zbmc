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
