<!-- html2md:auto source=boxes/openbmc/IPMI-REDFISH-INVENTORY.html -->

# openbmc — command inventory

Vanilla upstream OpenBMC (Phosphor, AST2600), `zbmc openbmc` @ 10.0.7.10 · obmc-phosphor-image @ openbmc 5d179dab (3.1.0-dev-294) · no vendor OEM (Mfr 0). Measured live 2026-07-18.

Method

**IPMI:** single cipher-17 RMCP+ session (zipmi lib), swept every even NetFn 0x00–0x3E × cmd 0x00–0xFF with *empty data*. Completion code reads: `0xC1`=command not registered · `0xC7`=registered (rejected on missing data — proves the handler exists without firing it) · `0x00`=zero-arg read executed. Cold/Warm Reset (App 0x02/0x03) blocklisted. Group NetFns re-probed with their selector byte. **Redfish:** authenticated BFS crawl from ServiceRoot (994 nodes; 810 are individual log entries + 115 JSON-schema files).

## IPMI — registered commands

73 standard handlers + 14 DCMI. NetFn 0x2E (OEM/IANA group) registered **zero** — **positively confirmed** by sweeping 11 IANAs (bogus 0xFFFFFF + Intel/Dell/NVIDIA/IBM/Google/Facebook/Ampere/HPE/OpenBMC/DMTF) × 256 cmds: every one returned 0xC1, and the bogus IANA behaves identically to every real vendor IANA → the group router has no registered groups. Consistent with the no-OEM baseline (the NVIDIA 0x3C BIOS-password handler is likewise absent).

### NetFn 0x00 — Chassis (10)

- 0x01 Get Chassis Capabilities
- 0x02 Chassis Control
- 0x04 Chassis Identify
- 0x05 Set Chassis Capabilities
- 0x06 Set Power Restore Policy
- 0x07 Get System Restart Cause
- 0x08 Set System Boot Options
- 0x09 Get System Boot Options
- 0x0A Set Front Panel Button Enables
- 0x0F Get POH Counter

### NetFn 0x04 — Sensor / Event (10)

- 0x02 Platform Event (Event Message)
- 0x20 Get Device SDR Info
- 0x21 Get Device SDR
- 0x22 Reserve Device SDR Repository
- 0x26 Set Sensor Threshold
- 0x27 Get Sensor Threshold
- 0x29 Get Sensor Event Enable
- 0x2D Get Sensor Reading
- 0x2F Get Sensor Type
- 0x30 Set Sensor Reading & Event Status

### NetFn 0x06 — Application (34)

- 0x01 Get Device ID
- 0x02 Cold Reset (blocklisted)
- 0x03 Warm Reset (blocklisted)
- 0x04 Get Self Test Results
- 0x06 Set ACPI Power State
- 0x08 Get Device GUID
- 0x24 Set Watchdog Timer
- 0x2E Set BMC Global Enables
- 0x2F Get BMC Global Enables
- 0x31 Get Message Flags
- 0x36 Get System Interface Capabilities
- 0x38 Get Channel Auth Capabilities
- 0x3B Set Session Privilege Level
- 0x3C Close Session
- 0x3D Get Session Info
- 0x40 Set Channel Access
- 0x41 Get Channel Access
- 0x42 Get Channel Info
- 0x43 Set User Access
- 0x44 Get User Access
- 0x45 Set User Name
- 0x46 Get User Name
- 0x47 Set User Password
- 0x48 Activate Payload
- 0x49 Deactivate Payload
- 0x4A Get Payload Activation Status
- 0x4B Get Payload Instance Info
- 0x4C Set User Payload Access
- 0x4D Get User Payload Access
- 0x4E Get Channel Payload Support
- 0x4F Get Channel Payload Version
- 0x54 Get Channel Cipher Suites
- 0x58 Set System Info Parameters
- 0x59 Get System Info Parameters

### NetFn 0x0A — Storage (15)

- 0x10 Get FRU Inventory Area Info
- 0x11 Read FRU Data
- 0x12 Write FRU Data
- 0x20 Get SDR Repository Info
- 0x22 Reserve SDR Repository
- 0x23 Get SDR
- 0x40 Get SEL Info
- 0x42 Reserve SEL
- 0x43 Get SEL Entry
- 0x44 Add SEL Entry
- 0x46 Partial Add SEL Entry
- 0x47 Clear SEL
- 0x48 Get SEL Time
- 0x49 Set SEL Time
- 0x5C Get/Set SEL Time UTC Offset

### NetFn 0x0C — Transport (4)

- 0x01 Set LAN Config Parameters
- 0x02 Get LAN Config Parameters
- 0x21 Set SOL Config Parameters
- 0x22 Get SOL Config Parameters

### NetFn 0x2C group 0xDC — DCMI (14)

- 0x00 Get DCMI Capabilities Info
- 0x01 Get Power Reading
- 0x02 Get Power Limit
- 0x03 Set Power Limit
- 0x04 Activate/Deactivate Power Limit
- 0x05 Get Asset Tag
- 0x06 Get DCMI Sensor Info
- 0x07 Set Asset Tag
- 0x08 Get MC Identifier String
- 0x09 Set MC Identifier String
- 0x0A Set Thermal Limit
- 0x10 Get Temperature Readings
- 0x12 Get DCMI Config Parameters
- 0x13 Set DCMI Config Parameters

## Redfish — resources & actions

~69 distinct service resources (excluding 810 individual `LogEntry` objects + 115 `JsonSchemaFile`s). Services present: AccountService, SessionService, CertificateService, UpdateService, TelemetryService, TaskService, EventService, plus Managers/bmc, Systems/system, Chassis, Storage, Processor, Switch collections.

### Action (POST) commands (8)

|  |  |
|----|----|
| ComputerSystem.Reset | /redfish/v1/Systems/system/Actions/ |
| Manager.Reset | /redfish/v1/Managers/bmc/Actions/ |
| Manager.ResetToDefaults | /redfish/v1/Managers/bmc/Actions/ |
| Bios.ResetBios | /redfish/v1/Systems/system/Bios/Actions/ |
| LogService.ClearLog | /redfish/v1/Systems/system/LogServices/EventLog/Actions/ |
| EventService.SubmitTestEvent | /redfish/v1/EventService/Actions/ |
| CertificateService.GenerateCSR | /redfish/v1/CertificateService/Actions/ |
| CertificateService.ReplaceCertificate | /redfish/v1/CertificateService/Actions/ |

`Bios.ResetBios` exists, but there is **no** BIOS-password get/set on this vanilla box over IPMI or Redfish.

## BIOS-password disclosure — vendor vs vanilla

The BIOS-password hash-disclosure primitive is an **OEM** addition, not upstream. Only **NVIDIA** and **Intel** register a BIOS-password IPMI handler, and both front the *same* upstream backend `bios-settings-mgr` → `/var/lib/bios-settings-manager/seedData` (plaintext JSON: Seed/salt + AdminPwdHash). Strip the vendor layer (this box) and the surface is gone.

<table>
<colgroup>
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
<col style="width: 20%" />
</colgroup>
<thead>
<tr class="text-slate-400 border-b border-slate-700 text-left">
<th class="py-2 pr-4">build</th>
<th class="pr-4">IPMI cmd</th>
<th class="pr-4">priv</th>
<th class="pr-4">gates</th>
<th>LAN-reachable?</th>
</tr>
</thead>
<tbody class="text-slate-400 align-top">
<tr class="border-b border-slate-800">
<td class="py-2 pr-4 font-mono text-amber-300">NVIDIA</td>
<td class="pr-4 font-mono">0x3C/0x37 Get<br />
0x3C/0x36 Set</td>
<td class="pr-4">Admin</td>
<td class="pr-4">none</td>
<td class="text-red-400"><strong>YES</strong> — returns action+salt[32]+hash[64] over the wire (PBKDF2, 1000 iters). The exposed one.</td>
</tr>
<tr class="border-b border-slate-800">
<td class="py-2 pr-4 font-mono text-amber-300">Intel</td>
<td class="pr-4 font-mono">0x30/0xD8 Get<br />
0x30/0xD7 Set</td>
<td class="pr-4">User</td>
<td class="pr-4"><code>getPostCompleted()</code> (pre-POST only) <strong>+</strong> allowlist <code>0x30:0xd8:0x0000</code> = disabled all channels</td>
<td class="text-emerald-400"><strong>NO</strong> — Intel is the only vendor that per-command LAN-filters; the allowlist blocks it on every channel (unless RestrictionMode≠Allowlist).</td>
</tr>
<tr class="border-b border-slate-800">
<td class="py-2 pr-4 font-mono text-emerald-300">vanilla (this box)</td>
<td class="pr-4 font-mono">—</td>
<td class="pr-4">—</td>
<td class="pr-4">n/a</td>
<td class="text-slate-400"><strong>absent</strong> — <code>0x3c 0x37</code> → 0xc1; NetFn 0x2E OEM = zero handlers.</td>
</tr>
</tbody>
</table>

So the leak severity is NVIDIA ≫ Intel ≫ vanilla: NVIDIA is Admin-but-unfiltered (wire-reachable), Intel registers it at lower priv but disables it on all channels + gates to pre-POST, vanilla lacks it entirely. Source: `OEM/intel-ipmi-oem/src/biosconfigcommands.cpp` + `ipmi-allowlist.conf:293-294`, `phosphor/oem/nvidia/biosconfigcommands.cpp`. See memory `reference_openbmc_oem_ipmi_census`, `reference_nvidia_oem_ipmi`.

Raw crawl + sweep data: `~/phd/tmp/evb-virtual/inventory/{ipmi,redfish}-inventory.{txt,json}`.
