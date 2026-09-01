# Security Policy

zbmc is an isolated-lab research tool. It boots proprietary BMC firmware with vendor defaults and
documented emulation adaptations. It is not a hardened service, sandbox, or production BMC.

## Supported branch

Security fixes are made on `main`. Report vulnerabilities through GitHub's private security advisory
workflow for `zenfish/zbmc`; do not include vendor firmware, private keys, or customer data in a public
issue.

## Trust boundary

- Run on a dedicated x86_64 Linux research host and keep the default addresses host-local.
- Docker packages exact QEMU builds, but uses host networking and writable work mounts. It is not a
  containment boundary.
- QEMU, console, QMP, captures, and evidence commonly run as root or contain root-controlled data.
- Do not route a virtual BMC to an untrusted network. Vendor defaults and research credentials are public.

## Deliberate adaptations

- MegaRAC-HPE's patched rootfs contains blank-password Dropbear and an unauthenticated telnet shell.
  They are not forwarded by default. `ZBMC_INSECURE_LAB_ACCESS=1` exposes them for isolated-lab work.
- iDRAC10 generates a per-installation SSH operator key under `work/idrac10/ssh/`. The supported package
  path is cold-only; the older shared warm checkpoint is not fetched or accepted by `start --warm`.
- iDRAC9 fetches a shared research login key paired with its prebuilt initramfs. Treat it exactly like a
  public default password.
- Supermicro X10 applies a research-only license-check interposition so the retained Redfish handler can
  be exercised. Confirm that your use is authorized before starting that box.
- Some retained snapshots can contain guest TLS/SSH host identities and captured runtime configuration.
  They are lab fixtures, not identity templates.

## Artifact provenance

Build recipes pin every fetched file by SHA-256. A hash proves identity and integrity, not vendor
authorization or redistribution rights. Several derived artifacts are project-mirror-only. The source,
transformation boundary, and known limitations are recorded in the box recipe and the engineering docs.
Do not publish a new firmware image or snapshot without checking it for credentials and machine-specific
configuration. Reachable published Git history still contains the former 67,109,128-byte
`firmware/encrypted_ASMB-787_20220912.ima_enc` blob even though the current tree does not. Audit or
rewrite that history as appropriate before mirroring or redistributing the repository.

## Host cleanup

Use `sudo ./tools/zbmc <box> stop` for managed runs. The dispatcher verifies run ownership using both PID
and process start time before signaling QEMU. `tools/zbmc-net teardown` removes only TAP interfaces it
recorded and restores its saved uplink address and route.
