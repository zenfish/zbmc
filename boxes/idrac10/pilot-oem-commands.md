# iDRAC10 Dell OEM IPMI Command Handlers — Pilot (12 commands)

Firmware: iDRAC10 1.30.10.50 (aarch64). Source libs: `rootfs-extracted/usr/lib/ipmi/*.so.9.9.9`.
Method: Ghidra 12.0 headless decompilation of the *defining* function body (resolved via `.dynsym`
name, not the dispatch-table thunk address). Dispatch metadata (netfn/cmd/priv/flags) from
`idrac10-dispatch-tables.md`.

This is a **calibration pilot**: the goal is to nail the per-command schema below so it can be
fanned out to all ~190 Dell OEM commands. See the closing "Scaling" section.

---

## Schema + method

Each command block has these fields. How each was derived:

- **Name / NetFn / Cmd / Privilege / Flags** — verbatim from `idrac10-dispatch-tables.md` (the dispatch
  entry). Priv: 0=None,1=Callback,2=User,3=Operator,4=Admin,5=OEM.
- **Defined in** — which `.so` actually contains the function body + its file-vaddr (from `objdump -T`,
  filtering out `*UND*` imports). The dispatch table in `liboemcmds`/`libipmicmdtableapi` often only
  holds a GLOB_DAT pointer to a symbol defined in another lib (e.g. `libmaser`, `libmisccmd`, `libosa`).
- **Purpose** — plain English, read off the decompiled control flow + log/`dlog_printf` format strings
  (many handlers log their own function name and a human description of each branch — a gift).
- **Request** — byte layout. **Calling convention** (constant across every handler, high confidence):
  the handler is `cc_t handler(REQ *req, u8 *resp_len, u8 *resp_data)`.
  - `req+7` = `u8CmdDataLen` — number of IPMI data bytes that follow (the handlers literally compare
    against this; confirmed by the group-extension commands placing the 3-byte IANA at req+8..+10).
  - `req+8` = **IPMI data byte 0** (`data[0]`), `req+9` = `data[1]`, … So *IPMI data-byte index N lives
    at req+8+N*. I give both the struct offset and the `data[N]` index.
  - `req+0` = a message-source/medium byte. Several handlers test `*req >> 4 == 7` to branch (e.g.
    pick a per-source scratch buffer). Interpreted as an internal channel/medium tag — **med
    confidence**; not attacker-supplied payload, so it doesn't affect the request wire format.
  - `req+1..+6` = session/lun/seq header, not parsed by these handlers.
- **Response** — bytes the handler writes. `*resp_len` (at the `resp_len` pointer) = number of data
  bytes; `resp_data[0..]` = payload; **completion code is the function return value** (separate from the
  data buffer). Standard CCs seen: `0x00` ok, `0xC7`(199) req-length-invalid, `0xCC` invalid data
  field / unknown subcommand, `0xD4` insufficient-priv/security-restriction (used here for the
  out-of-band rejection), `0x80` OEM "feature disabled", `0xC0` node busy, `0xC9` param out of range,
  `0xCB` requested data not present, `0xFF` unspecified.
- **Backend deps** — cfgdb keys (`CfgGetAttribute*`/`CfgSetAttribute*`), files (`fopen64`/`stat64`
  paths), dbus (`sd_bus_*`/`dbusMethodCall`), IPC clients (`*_IPCClient`), hardware/RAC APIs. Taken
  directly from the calls in the decompilation. These predict what is exercisable on the emulator.
- **Security notes** — reachability gate (in-band-only vs LAN), what it writes/exposes, cred/cert/FW
  relevance.
- **Confidence** — high/med/low + what's uncertain.

**Reachability gates (recurring, high confidence):**
- `IsInBandCommand()` / `IsMsgFromSystemInterface()` (both imported) == "request came from the host-side
  KCS/system interface." Many OEM 0x30 and both 0x2c commands **reject out-of-band (LAN/RMCP+) callers**
  outright (`0xD4` or `0x01`). This is the single biggest testability fact: on the emulated box these are
  only reachable via the host KCS path, not remote IPMI.

**Per-command cost:** ~5–8 min each wall-clock, but that is dominated by one-time Ghidra
import+auto-analysis per lib (4 libs, run in parallel). Actual marginal decompile+read is ~2 min/command.
All 12 were Ghidra decompilation (no objdump fallback needed); decompiler output quality was high
(named cfgdb keys, named sub-handlers, self-logging format strings).

---

## 1. CmdGetExtendedConfigure

- **NetFn / Cmd / Priv / Flags:** 0x2E (Group/IANA) / 0x02 / User(2) / 0x89
- **Defined in:** `liboemcmds.so.9.9.9` @ 0x197c0 (size 0x3f4)
- **Purpose:** Read a chunk of the RAC "extended configuration" blob addressed by a *token* (config
  class) and *index*, with a reserve-ID handshake and offset-based chunked read (≤0x80 bytes per call).
  This is the IPMI transport for Dell's RACADM/token config store.
- **Request:** `req+7` datalen **must == 9**.
  | struct off | data[] | field | meaning |
  |---|---|---|---|
  | +8..+10 | data[0..2] | IANA (LE, 3B) | must == 0x0002A2 (Dell, 674) else `0xCC` |
  | +11 | data[3] | reserve id | reservation handle |
  | +12 | data[4] | token (`bVar2`) | config class; token 0x0B = special "version/build" fast-path |
  | +13 | data[5] | index (`bVar3`) | instance index |
  | +14..+15 | data[6..7] | offset (u16 LE) | read offset into blob; 0 = start (reloads blob) |
  | +16 | data[8] | read len | bytes to return (clamped to 0x80) |
- **Response:** `data[0..1]`=IANA low echo, `data[2]`=IANA high, `data[3]`=token, `data[4]`=index,
  `data[5]`=byte count returned, `data[6..]`=config bytes. `*resp_len = count + 6`. CC `0x00`.
  Token-mismatch across a chunked read → `0xC9`. Token validity checked by `FUN_00116eb0(token,…)`.
- **Backend deps:** `GetRACExtendedConfig()` (RAC token store). Two static 0x6000-byte (24KB) scratch
  buffers keyed by request source (`*req>>4==7` picks `DAT_001597c8` vs `DAT_0015f7d8`). Token 0x0B
  returns fixed bytes `DAT_00137d10..20` (build/version).
- **Security notes:** User priv, but a **read** primitive over the whole RAC config token space; content
  sensitivity depends on token. No auth beyond IPMI session priv. Chunked-read state is global/shared
  (per-source buffer) → possible cross-session read interleaving if two Users race the same source tag.
- **Confidence:** high on request layout & token/offset semantics; med on the `*req>>4==7` source-tag
  buffer selection (interpretation of req+0).

## 2. CmdSetExtendedConfigure

- **NetFn / Cmd / Priv / Flags:** 0x2E (Group/IANA) / 0x03 / Admin(4) / 0x89
- **Defined in:** `liboemcmds.so.9.9.9` @ 0x19bb4 (size 0x3cc)
- **Purpose:** Write side of the token config store. Accumulates payload chunks into a 24KB buffer and
  commits via `SetRACExtendedConfig()` when the "commit" byte is set. Requires a matching reserve ID.
- **Request:** `req+7` datalen **must be ≥ 9**.
  | struct off | data[] | field | meaning |
  |---|---|---|---|
  | +8..+10 | data[0..2] | IANA (LE) | must == 0x0002A2 else `0xCC` |
  | +11 | data[3] | reserve id | must == `G_u8RacResvID` (from CmdResvExtendedConfigure) else `0xC5` |
  | +12 | data[4] | token | config class |
  | +13 | data[5] | index | instance |
  | +14..+15 | data[6..7] | offset (u16 LE) | write offset; must match accumulated length else `0xC9` |
  | +16 | data[8] | commit flag | ==1 → call `SetRACExtendedConfig` and reset buffer |
  | +17.. | data[9..] | payload | `datalen-9` bytes, memcpy into `DAT_001537bc` (cap 0x6000) |
- **Response:** `data[0..1]`=IANA low echo, `data[2]`=IANA high, `data[3]`=bytes-written-this-chunk.
  `*resp_len = 4`. CC `0x00`; commit failure → `0xCC`.
- **Backend deps:** `SetRACExtendedConfig()`; global 0x6000 accumulation buffer + length/token/index
  state (`DAT_001537b8`, `DAT_001597bc`, `DAT_001597c0`).
- **Security notes:** **Admin write primitive into the RAC config token store** — the mutating
  counterpart to #1. Reserve-ID handshake is the only integrity gate; no per-token ACL visible at this
  layer. High-value: whatever RACADM/iDRAC config is token-addressable can be set here. `memcpy` is
  length-clamped to 0x6000 (no obvious overflow), offset must equal running length (no arbitrary seek).
- **Confidence:** high.

## 3. CmdResetToDefault

- **NetFn / Cmd / Priv / Flags:** 0x2E/0x21 **and** 0x30/0x21 (two dispatch entries, same handler) / Admin(4) / 0x01
- **Defined in:** `libosa.so.9.9.9` @ 0x6864 (size 0x26c)
- **Purpose:** Reset iDRAC configuration to defaults (RTD). data[0] selects a query vs a
  reset-variant; the actual reset runs on a detached worker thread.
- **Request:** `req+7` datalen **must == 1**.
  | struct off | data[] | field | meaning |
  |---|---|---|---|
  | +8 | data[0] | RTD mode | `0x00` = **query status only** (returns whether an RTD lock is present); other values = perform reset |
  - For reset: `data[0]` must be `0xAA`, `0xCC`, or fall in a bitmap of allowed variant codes
    (`(bVar5+0x23)` in {…}; the `0x400020001` mask). Else `0xCC`. Special: `data[0]==0xAA` and
    `*req>>4==7` (host source) is rewritten to variant `0xDD`.
- **Response:** Query mode: `*resp_len=1`, `resp_data[0]` = `stat64("/var/lock/rtd/r2default.lock")!=0`
  (1 = no lock / idle). Reset mode: `*resp_len=1`, `resp_data[0]=0`, CC `0x00` after spawning worker.
- **Backend deps:** `stat64("/var/lock/rtd/r2default.lock")`; `preChecks()`;
  `IsFirmwareUpdateInProgress()` (blocks RTD during FW update → `0xC0`); worker
  `threadResetToDefault` (→ `CfgResetConfigToDefaults`, `CfgDAResetToDefaults`, `PEFLANCfgResetToDefault`,
  `ResetLANIPCfgToDefault`, `run_mount_maser_as_root` per libosa imports).
- **Security notes:** **Destructive.** Admin-gated factory/config reset of the iDRAC. Refuses while a FW
  update is in progress. The `0xAA→0xDD` host-only rewrite implies a broader "full reset" variant only
  reachable from the system interface. Async (returns before completion) — status pollable via query mode.
- **Confidence:** high on flow & lock file; med on the exact meaning of each allowed variant code
  (bitmap decoded but per-code semantics not individually labeled in this function).

## 4. CmdOEMvFlash

- **NetFn / Cmd / Priv / Flags:** 0x30 (Dell OEM) / 0xA4 / User(2) / 0x81
- **Defined in:** `libmaser.so.9.9.9` @ 0x21510 (size 0x464)
- **Purpose:** vFlash (SD-card virtual flash) management dispatcher. `data[0]` = subcommand selecting a
  vFlash operation; routes to a dedicated sub-handler.
- **Request:** `req+8` = `data[0]` = subcommand. Sub-handler parses the rest.
  | data[0] | sub-handler |
  |---|---|
  | 0x00 | `CmdOEMVflashGetCardInfo` |
  | 0x01 | `CmdOEMVflashCardControl` (enable/disable vFlash) |
  | 0x10 | `CmdOEMVflashGetPartitionIndexInfo` |
  | 0x11 | `CmdOEMLVflashGetPartitionInfo` |
  | 0x12 / 0x13 | `CmdOEMVflashAttachPartitions` / `…Detach…` |
  | 0x14 / 0x15 | `…SetBootPartition` / `…GetBootPartition` |
  | 0x20 / 0x21 | `…CreateEmptyPartition` / `…FormatPartition` |
  | 0x22 / 0x23 | `…ChangePartitionAccessType` / `…DeletePartition` |
  | 0x24 / 0x25 | `…GetJobStatus` / `…GetPartitionStatus` |
  | other | `0xCC` |
- **Response:** produced by the sub-handler (`*resp_len`,`resp_data`), CC returned through.
- **Backend deps:** `IsMsgFromSystemInterface` gate; VFL_* API (`VFL_Boot_VFlash_Label`,
  `VFL_Boot_VFlash_Partition`, `VFL_Disable_vFlash`, `VFL_List_SD_Card_Info`), SD-card device.
- **Security notes:** **In-band-only** (`IsMsgFromSystemInterface==0 → CC 0x01`). User priv but not
  LAN-reachable. Attach/format/delete-partition + set-boot-partition = full control over the vFlash
  virtual media the host can boot from (attack surface: host boot-image substitution) — but only from
  the host side. This handler is the parent of the historical VFLASH-LABEL-TRAVERSAL / IMAGE-URL issues.
- **Confidence:** high for the dispatch map; sub-handler byte layouts not expanded (each is its own
  command in the full fan-out).

## 5. CmdOEMBackupRestore

- **NetFn / Cmd / Priv / Flags:** 0x30 (Dell OEM) / 0xA6 / User(2) / 0x81
- **Defined in:** `libmaser.so.9.9.9` @ 0x21a40 (size 0x354)
- **Purpose:** iDRAC/system config **Backup & Restore** (SCP-style) dispatcher over the MASER
  (Managed Storage / partition) subsystem. `data[0]` = subcommand.
- **Request:** `req+8` = `data[0]` = subcommand:
  | data[0] | sub-handler |
  |---|---|
  | 0 | `CmdOEMBnRPopulateBackupCmd` |
  | 1 | `CmdOEMBnRSendBackupCmd` |
  | 2 | `CmdOEMBnRPopulateRestoreCmd` |
  | 3 | `CmdOEMBnRSendRestoreCmd` |
  | 4 | `CmdOEMBnRQueryJobStatus` |
  | 5 | `CmdOEMBnRQueryJobID` |
  | 6 | `CmdOEMBnRCancelCmd` |
  | 7 | `CmdOEMBnRSetJobStatusCmd` |
  | 8,9 | reserved → CC 0x01 |
  | 10 | `CmdOEMBnRGetAutoFeatureStatus` |
  | 0x0B | `CmdOEMBnRGetAutoRestoreVflCap` |
  | other | `0xCC` |
- **Response:** from sub-handler.
- **Backend deps:** `IsMsgFromSystemInterface` gate; MASER partition storage, job queue, vFlash
  (auto-restore capability).
- **Security notes:** **In-band-only.** Backup/restore moves the *entire* iDRAC config profile (creds,
  certs, licenses) to/from a MASER partition. Restore = config-injection primitive; "SetJobStatus"
  (sub 7) mutating job state is worth a dedicated look. Not LAN-reachable at this layer.
- **Confidence:** high for dispatch; sub-handlers deferred.

## 6. CmdOEMSupportAssist

- **NetFn / Cmd / Priv / Flags:** 0x30 (Dell OEM) / 0xA8 / User(2) / 0x81
- **Defined in:** `libmaser.so.9.9.9` @ 0x30644 (size 0x628)
- **Purpose:** SupportAssist (SA) / iSM collection control: expose/hide the iSM installer, start/stop
  native-OS log collection, initiate/cancel an SA data collection, query status. `data[0]`=subcommand.
- **Request:** `req+8` = `data[0]` subcommand:
  | data[0] | action / sub-handler |
  |---|---|
  | 0 | `CmdOEMSANativeOSCollection` (is supported) |
  | 1 / 2 | `…NativeOSCollectionStarted` / `…Ended` |
  | 3 / 4 | `CmdOEMSAExposeiSMInstaller` / `…HideiSMInstaller` |
  | 5 | `CmdOEMSAGetStatus` (last command status) |
  | 6 | `CmdOEMSACollectData` (initiate collection) |
  | 7 | `CmdOEMSAGetCollectDataStatus` |
  | 8 | `CmdOEMSAHideCollectDataResult` |
  | 9 | `CmdOEMSACollectDataCancel` |
  | 0x10 | `CmdOEMSAJobInProgressPendingSignal` |
  | other | `0xCC` |
- **Response:** `resp_data[0]` set by sub-handler; CC = sub-handler return.
- **Backend deps:** `IsMsgFromSystemInterface` gate; MASER partition (collection output), iSM installer
  image exposure (mounts a virtual device visible to host OS).
- **Security notes:** **In-band-only.** "Expose iSM installer" surfaces an installer image to the host —
  a BMC→host software-delivery channel worth scrutiny. Data collection can gather host logs. Host-side
  only.
- **Confidence:** high for dispatch (self-logging strings label each branch); sub-handlers deferred.

## 7. CmdOEMDellFactory

- **NetFn / Cmd / Priv / Flags:** 0x30 (Dell OEM) / 0xA5 / User(2) / 0x81
- **Defined in:** `libmaser.so.9.9.9` @ 0x45de0 (size 0x31c)
- **Purpose:** Factory/manufacturing operations: query factory status, trigger platform-cache cleanup,
  create factory HW inventory XML (worker thread), and set the **secure default password**.
- **Request:** `req+7` datalen normally **== 6** (except the secure-default-password path which is length
  4 / branch when `data[0]==4`). `req+8` = `data[0]` = command type:
  | data[0] | action |
  |---|---|
  | 0 | create factory HW inventory (spawns `threadCreateFactoryHWInventory`) |
  | 1 | recreate MASER images (deprecated → `0xCC`) |
  | 2 | **factory status** query; returns state byte from `DAT_0018c480[data[1]]`, `data[1]`(req+9) ≤4 |
  | 3 | write "features/platform cache cleanup request" to `/flash/data0/features/system-id` |
  | 4 | **CMD_MASER_FACTORY_SECURE_DEFAULT_PASSWORD** → `CmdOEMSecureDefaultPassword` |
  | ≥5 | out of range → `0xCC` |
- **Response:** status path `*resp_len=4`, `resp_data[0]=data[1]`, `resp_data[1]=state`, else per-branch.
- **Backend deps:** **`IsMsgFromSystemInterface` gate**; `IsInManufacturingTestMode(2)` (must be in mfg
  mode else `0x09`); `IsMASERInit`/`IsMASERDisabled` (else `0x05`); file
  `/flash/data0/features/system-id`; worker `threadCreateFactoryHWInventory`; `CmdOEMSecureDefaultPassword`.
- **Security notes:** **In-band-only AND manufacturing-mode-gated** — strongest gating in the pilot. The
  secure-default-password subcommand (data[0]=4) is the most sensitive (sets the factory default
  credential); it delegates to `CmdOEMSecureDefaultPassword` — a priority follow-up target. Not
  attacker-reachable on a production, non-mfg-mode, remote box.
- **Confidence:** high on flow/gates; the `DAT_0018c480` factory-status byte table contents are runtime
  state (undetermined statically — marked so).

## 8. CmdOEMGetMASERInfo

- **NetFn / Cmd / Priv / Flags:** 0x30 (Dell OEM) / 0xAB / User(2) / 0x03
- **Defined in:** `libmaser.so.9.9.9` @ 0x1d6c0 (size 0x3e4)
- **Purpose:** Report MASER (managed-storage / SD) info for a given MASER type: presence, in-use flags,
  media type (SD/MMC), size.
- **Request:** `req+7` datalen **must == 3**. `req+8` = `data[0]` = **MASER type**:
  | data[0] | meaning |
  |---|---|
  | 0x00 | reads `/var/tmp/maser0.info` |
  | 0x01 | SD-card MASER: `aim_config_get_bool("ameastatus_bool_amea_sd_present")`, `VFL_List_SD_Card_Info`, reads `/var/tmp/maser1.info` |
  | other | invalid → `0xCB` |
- **Response:** `*resp_len=10`. `resp_data[0]`=type, `resp_data[1]`=media class (0x4453="SD" → 0/1,
  else "MMC"→2), `resp_data[2..3]`=size (`local_a8`), `resp_data[6]`=flags (bit0 SD-in-use, bit1 label
  present, bit2 vFlash-in-use). Missing info file → `0xCB`.
- **Backend deps:** files `/var/tmp/maser{0,1}.info` (parsed by `FUN_0010e1d0`); `aim_config_get_bool`
  (AIM config store); `VFL_List_SD_Card_Info`; `VFlash_in_use`.
- **Security notes:** Read-only info leak (SD presence/size/label state). **No** `IsMsgFromSystemInterface`
  gate in this handler → potentially LAN-reachable at User priv (unlike its sibling MASER commands).
  Low direct impact but a fingerprinting/recon primitive.
- **Confidence:** high on request length & type; med on exact response field widths beyond the labeled
  flags (some come from the .info file parse `FUN_0010e1d0`, not expanded).

## 9. CmdOEMToolSet

- **NetFn / Cmd / Priv / Flags:** 0x30 (Dell OEM) / 0xA7 / User(2) / 0x81
- **Defined in:** `libmaser.so.9.9.9` @ 0x2f8f0 (size 0x200)
- **Purpose:** "ToolSet" dispatcher — expose/hide executables to the host, collect data, marker
  begin/update/end, and **system erase**. `data[0]`=subcommand.
- **Request:** `req+8` = `data[0]` subcommand:
  | data[0] | sub-handler |
  |---|---|
  | 0 / 1 | `CmdOEMTSExposeExecs` / `CmdOEMTSHideExecs` |
  | 2 | `CmdOEMTSGetStatus` |
  | 3 | `CmdOEMTSCollectData` |
  | 4 | `CmdOEMTSGetDataInfo` |
  | 5 / 6 / 7 | `CmdOEMTSBeginMarker` / `…EndMarker` / `…UpdateMarker` |
  | 8 | **`CmdOEMTSSystemErase`** |
  | other | `0xCC` |
- **Response:** from sub-handler (`resp_data[0]`), CC returned.
- **Backend deps:** `IsMsgFromSystemInterface` gate; MASER partition; host-exposed executables channel.
- **Security notes:** **In-band-only.** `CmdOEMTSSystemErase` (data[0]=8) is **destructive** (system
  erase / secure-wipe) — a priority follow-up. "ExposeExecs" is another BMC→host code-delivery surface.
- **Confidence:** high for dispatch; sub-handlers deferred.

## 10. CmdOEMRemoteEnablement

- **NetFn / Cmd / Priv / Flags:** 0x30 (Dell OEM) / 0xA3 / User(2) / 0x80
- **Defined in:** `libmaser.so.9.9.9` @ 0x21260 (size 0x2a8)
- **Purpose:** Remote Enablement / auto-discovery (zero-touch provisioning) dispatcher. Lazily builds a
  `{subcommand → handler}` table on first call, then dispatches `data[0]` through it.
- **Request:** `req+8` = `data[0]` = subcommand. Table (built once into `DAT_0018bc38/40`):
  | data[0] | handler |
  |---|---|
  | 0 / 1 | `CmdOEMGetAutoDiscovery` / `CmdOEMSetAutoDiscovery` |
  | 2 | `CmdOEMSignCertificate` |
  | 3 | `CmdOEMGetCertificateStatus` |
  | 4 / 5 | `CmdOEMGetRECapabilitiesBitmap` / `…Set…` |
  | 6 / 7 | `CmdOEMGetProvisioningServerInfo` / `…Set…` |
  | 8 / 9 | `CmdOEMGetDiscoveryRestartOptions` / `…Set…` |
  | 0x0A..0x11 | CCR feature/update-mode/config/auto-sync get/set pairs |
  | 0x12 | `CmdOEMGetDHStatus` |
  | 0x13 | `CmdOEMRemoveCertificate` |
  | 0x14 | `CmdOEMSkipISOBoot` |
  | 0x15 | `CmdOEMDisconnectNetworkISO` |
  | 0x16 | `CmdOEMChangeRFSToAttachMode` |
  | 0x17 | `CmdOEMReCapabilityForDup` |
  | 0xFFFFFFF0 | `CmdOEMUEFILOGService` |
  | no match | `0xCC` (returns 0xFFFFFFCC) |
- **Response:** from the selected sub-handler.
- **Backend deps:** provisioning/auto-discovery config, certificate store (sign/remove/status), network
  ISO / remote-file-share attach. **No** `IsMsgFromSystemInterface` gate at this dispatcher level (unlike
  the other 0x30 MASER commands) — sub-handlers may gate individually.
- **Security notes:** High interest. `CmdOEMSignCertificate` / `CmdOEMSetProvisioningServerInfo` /
  `CmdOEMSetAutoDiscovery` touch the zero-touch-provisioning trust chain (cf. iDRAC9 discovery-cert
  fleet-key work). User priv + no in-band gate here means these may be **LAN-reachable** — verify each
  sub-handler's own gating. `CmdOEMDisconnectNetworkISO` / `SkipISOBoot` affect host boot media.
- **Confidence:** high for dispatch table; per-sub-handler gating undetermined here (deferred).

## 11. DellCmdGetBootstrapCredentials

- **NetFn / Cmd / Priv / Flags:** 0x2C (DCMI namespace) / 0x02 / Admin(4) / 0x02
- **Defined in:** `libmisccmd.so.9.9.9` @ 0x2cc40 (size 0x254)
- **Purpose:** Redfish/host-interface **credential bootstrapping** — generate and return a one-time
  IPMI/Redfish bootstrap username+password to the host (DMTF Redfish Host Interface bootstrap flow).
  One of the two *new* iDRAC10 0x2C commands.
- **Request:** `req+7` datalen **must == 2**.
  | struct off | data[] | field | meaning |
  |---|---|---|---|
  | +8 | data[0] | magic | must == `'R'` (0x52) else `0xCC` |
  | +9 | data[1] | disable-after flag | `0xA5` = keep provisioning enabled; **any other value disables** `IPMIBootstrapCredentialProvisioning` after this read |
- **Response:** `resp_data[0]=0x52`('R'), `resp_data[1..32]` = 32 bytes credential material
  (username+password), `*resp_len = 0x21` (33). CC `0x00`.
  Failure CCs: `0xD4` not in-band, `0xC7` bad len, `0xCC` bad magic, `0x80`
  provisioning-disabled/read-fail, `0xFF` generation/format failure.
- **Backend deps:** **`IsInBandCommand()` gate** (out-of-band → `0xD4`); cfgdb key
  `iDRAC.Embedded.1#Security.1#IPMIBootstrapCredentialProvisioning` (int; must be non-zero);
  `GenerateBootstrapCredentials_IPCClient()` (IPC to the credential service);
  `CfgSetAttributeInt(...=0)` to auto-disable.
- **Security notes:** **Highest-value in the pilot.** Hands out working management credentials. Gated by
  (a) in-band only, (b) the `IPMIBootstrapCredentialProvisioning` cfg flag being enabled, (c) magic 'R'.
  This is the Redfish "credential bootstrapping" feature — if the provisioning flag can be left enabled
  and a host-side agent (or host-RAM/KCS pivot) reaches it, it yields fleet-relevant creds. Cross-refs
  iDRAC9/10 factory-cred research. Confirm the cfg-flag default state and whether `Generate…IPCClient`
  derives from a fleet-static secret.
- **Confidence:** high on request/response wire format and gating; med on the *content/derivation* of
  the 32 returned bytes (produced in the IPC service, not this function).

## 12. DellCmdGetMgrCertFingerprint

- **NetFn / Cmd / Priv / Flags:** 0x2C (DCMI namespace) / 0x01 / Admin(4) / 0x02
- **Defined in:** `libmisccmd.so.9.9.9` @ 0x2ca10 (size 0x230)
- **Purpose:** Return the iDRAC manager **TLS certificate SHA-256 fingerprint** to the host, so a host
  agent can pin/verify the Redfish endpoint before using bootstrap creds (#11). Second new 0x2C command.
- **Request:** `req+7` datalen **must == 2**.
  | struct off | data[] | field | meaning |
  |---|---|---|---|
  | +8 | data[0] | magic | must == `'R'` (0x52) else `0xCC` |
  | +9 | data[1] | subcommand | must == `0x01` else `0xCB` |
- **Response:** `resp_data[0]=0x52`('R'), `resp_data[1]=0x01`, `resp_data[2..33]` = 32-byte SHA-256
  fingerprint (hex string from cfgdb, `StringToHex`'d to raw 32B). `*resp_len = 0x22` (34). CC `0x00`.
  Failure: `0xD4` not in-band, `0xC7` bad len, `0x80` provisioning disabled, `0xFF`
  read/convert failure (incl. stored fingerprint string length != 0x41).
- **Backend deps:** **`IsInBandCommand()` gate**; cfgdb keys
  `iDRAC.Embedded.1#Security.1#IPMIBootstrapCredentialProvisioning` (must be enabled) and
  `iDRAC.Embedded.1#Security.1#TLSCertificateFingerPrint` (65-char hex string); `StringToHex`.
- **Security notes:** In-band, provisioning-flag-gated. Info-only (public cert fingerprint) but it is the
  trust anchor for the bootstrap-cred flow — pairs with #11. Note the fingerprint lives in cfgdb, so
  it's also readable to anything that can read that key directly.
- **Confidence:** high.

---

## Scaling to ~190 Dell OEM commands

**What worked (keep):**
- Resolve each handler's *defining* lib+addr by name via `objdump -T | grep -v '*UND*'` before touching
  Ghidra. The dispatch-table address is just a GLOB_DAT thunk; ~2/3 of `liboemcmds` OEM 0x30 entries are
  `DellDCSSCBMCWrapper`/`DellNMCommand`/`SubCmdHandler` shells whose real bodies live in
  `libmaser`/`libmisccmd`/`libosa`/`libifru`/etc.
- One Ghidra headless import+analysis **per lib** (not per command), then a single `-process -noanalysis`
  pass running `DecompByName` with *all* target names for that lib. Look up functions by `.dynsym`
  **name**, not rebased address (Ghidra rebased `.so` to imageBase 0x100000 — the raw file-vaddr misses).
- Self-logging `dlog_printf("%s: …", "CmdX")` format strings label almost every branch — dispatch maps
  and subcommand meanings fall out for free.

**Batching plan:**
1. Build one CSV: `symbol, netfn, cmd, priv, flags, defining_lib, addr` by joining the dispatch md with
   the `objdump -T` defined-symbol map across all `*.so.9.9.9`. Group by `defining_lib`.
2. Distinct libs are few (~6: `liboemcmds`, `libmaser`, `libmisccmd`, `libosa`, `libifru`, `libdcmi`,
   plus a handful). Import each **once** (parallel; libmaser ~508KB is the long pole at a few min).
3. Per lib, one `DecompByName` batch over every target symbol → one `.c` file per lib. This is the
   parallelizable unit. ~190 commands = ~6 Ghidra runs, not 190.
4. **Deduplicate dispatchers:** many 0x30 subcommands funnel through a handful of parent dispatchers
   (`CmdOEMvFlash`, `CmdOEMBackupRestore`, `CmdOEMToolSet`, `CmdOEMSupportAssist`, `CmdOEMRemoteEnablement`,
   `DellNMCommand`, `SubCmdHandler`, `DellDCSSCBMCWrapper`). Document the parent once, then treat each
   sub-handler (`CmdOEMVflash*`, `CmdOEMBnR*`, `CmdOEMTS*`, `CmdOEMSA*`, `CmdOEM*` RE) as its own leaf
   command — that is where the real per-subcommand request bytes live. The true command count is larger
   than 190 once subcommands are counted; the dispatch entry is only the first hop.
5. Fan-out authoring: feed each lib's `.c` batch to a documentation pass (subagent per lib) emitting the
   schema block above. The calling convention (`req+7`=len, `req+8+N`=data[N], return=CC, `*resp_len`,
   `resp_data`) and the gate vocabulary (`IsInBandCommand`/`IsMsgFromSystemInterface`, standard CCs) are
   now fixed constants — no re-derivation needed.

**Schema fields that were hard / partly undetermined (flag these up front in the fan-out):**
- **req+0 source/medium byte** (`*req>>4==7`): interpreted as internal channel tag, not proven. Doesn't
  change wire format but affects a few branch decisions.
- **Response field widths beyond the labeled bytes**: when a response is filled from a helper
  (`FUN_0010e1d0` parsing `.info` files, or `GenerateBootstrapCredentials_IPCClient`), the *structure* is
  clear but individual sub-fields require decompiling the helper — defer to a second tier if needed.
- **Runtime-state tables** (e.g. `DAT_0018c480` factory-status bytes): contents are set at runtime;
  statically "undetermined" — mark, don't guess.
- **Backend value semantics**: cfgdb key *names* are recovered verbatim (high value), but the *meaning*
  of returned cred/status bytes lives in the IPC service on the other side of `*_IPCClient` — a separate
  RE target (those services, not these handlers).
- **Per-subcommand gating** for dispatchers with no top-level `IsMsgFromSystemInterface` check
  (RemoteEnablement, GetMASERInfo): must be read from each leaf handler; do not assume the parent's gate.

**Wall-clock:** pilot = ~35 min total for 12 (dominated by 4 parallel Ghidra imports + reading). At
scale, marginal cost is ~2–3 min per *leaf* command once the lib is imported; the 6 imports amortize
across all ~190+. All Ghidra (decompiler), no objdump fallback required.
