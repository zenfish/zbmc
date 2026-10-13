<!-- html2md:auto source=boxes/lenovo-xcc/lenovo-xcc-oem-authorization.html source-sha256=3a8c6cae00e7b5fc825776e56137802bd71ad4f9945b853ce3bc4e0ed4aa3deb body-sha256=6dfd4e4d76efac66412452a5f254fd81edad82fee93eb34bf24610c103971a4a -->

Lenovo XCC 6.92 · Newyork-pass1

# OEM IPMI authorization audit

The exact firmware admits several control commands at IPMI User privilege. A separate ReadOnly, IPMI-only account negotiated User privilege over RMCP+ cipher 17, reached sensitive command handlers, and successfully reset XCC configuration to defaults. This is a demonstrated authorization weakness in the emulated XCC 6.92 image; physical-hardware applicability is untested.

## Primary finding: OSA inner privilege is ignored

The outer `2e/cc` dispatch row in `libipmi.so` requires privilege `02` (User). The 27-row OSA inner table carries a privilege byte, including `04` (Administrator) on sensitive leaves. `CmdOSAOEMCmdHandler` checks each row's key and length and calls its function pointer; it never reads that inner privilege byte. The examined sensitive leaves contain no later privilege check.

Live proof: the User account received a successful response from the inner Admin “Get BMC Slave Address” route (`2e/cc 5e2b000642` → `CC00 5e2b00064220`). Eleven other inner routes, including reset-to-default, graceful reset, GUID, BMC address, power, network, sensor, and memory controls, returned the handler's `C7` length error to deliberately incomplete requests. A genuine Admin-gated command, `3a/c7`, returned `D4` to the same User account and succeeded as Administrator.

Impact proof: on a disposable warm restore, the same ReadOnly User account sent exactly one valid reset request, `2e/cc 5e2b000a01ff000000`. XCC returned `CC00 5e2b000a0100`; the final status byte is success. The proper Admin-gated `3a/c7` control still returned `D4` in that session. No request retransmission was enabled. The VM was then stopped and restarted from its immutable checkpoint.

## Other User-level surfaces

| Command | Observed User result | Impact supported by static analysis |
|----|----|----|
| 3a/94 | Empty request → C7 | Arbitrary I²C bus/address write-read after a 3–34-byte length check; no internal authorization. |
| 3a/38 | Empty request → C7 | Host NMI and optional reset/power cycle; no internal authorization. |
| 2e/90, 2e/97 | Short datastore bodies → C9; short TKLM body → C7 | Datastore and key-lifecycle handlers are reachable; subordinate operations were not executed. |
| 3a/0c, 3a/59, 3a/5a | Empty requests → C7 | VPD write and replication handlers are reachable; exact impact needs bounded payload review. |

Static-only priorities: `2e/81` firmware method invocation, `2e/96` eMMC sanitization, and `3a/6e` PFR EC reset/update all have User-level registration and no discovered secondary authorization. No harmless body has yet been established for these, so they were not probed. Recovery `3a/da` is an important exception: it explicitly requires the UEFI interface and returns `D5` on other interfaces.

## Method and boundaries

- Target: XCC 6.92 Newyork-pass1; rootfs SHA-256 `2aaedcb6c5939efabd49ac4da0a8066e17c5c3dea356ad33ad0d9246c4b192c2`; `libipmi.so` SHA-256 `b72294cd8a10699e2cd3827dd1b4aa0a13943c483332af0ceae8ba603cf17485`.
- A temporary ReadOnly, IPMI-only account was created in the disposable QEMU guest. It authenticated with requested User privilege `2`; a request for Operator privilege was denied. The existing administrator account was tested separately at privilege `4`.
- Both accounts received 27 identical exact requests. The final runs have zero transport errors. All state-changing probes carried bodies too short to reach their effect paths. User and Admin returned matching handler errors for every such tested route.
- User `3a/7b` returned `D5` on LAN, and physical-presence getters `3a/7c` and `3a/7d` returned `C1`; these are not evidence of general LAN reachability for those handlers.
- QEMU's active eMMC drive used `snapshot=on` over a matched, immutable warm checkpoint. An earlier impact attempt did not send a reset request: RMCP+ Open Session timed out and QEMU was found down, with no cause in the inspected logs. The checkpoint was restored; the later single valid User-level reset succeeded. The VM was stopped and restarted from the matched checkpoint afterward.

Exact machine-readable results: [User account](evidence/20260926T-user-authorization.json), [Administrator account](evidence/20260926T-admin-authorization.json), and [single factory-reset impact request](evidence/20260926T-user-factory-reset.json). Reproducible guarded probe matrix: [audit-oem-authorization.py](audit-oem-authorization.py). Full catalog: [XCC OEM reference](lenovo-xcc-oem-reference.md).
