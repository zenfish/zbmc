<!-- html2md:auto source=boxes/megarac-hpe/IPMI.html -->

# IPMI stack teardown — Cray XD670 (MegaRAC SP-X)

What handles IPMI, the supported command set, and the OEM commands — enumerated live off the running box (IPMI firmware-firewall) and extracted from the handler `.so`s (ELF symbols). AMI MegaRAC SP-X 13.x LTS / AST2600.

## What handles IPMI

`IPMIMain` is the dispatcher. Requests arrive on per-channel **interface libs** — `libipmilan` (RMCP+/LAN), `libipmikcs` (KCS), `libipmibt` (BT), `libipmiserial`/`libipmisol`, `libipmissif`, `libipmiusb`, `libipmiipmb`, and `libipmilocal` (the UDS `/var/UDSocket1` path that Redfish/racadm use). IPMIMain routes each `(NetFn, Cmd)` via its tables (`CoreNetfntbl` → `ExtNetFnMap` → `AMIOEMTable`) to a handler. Standard commands live in `libipmi.so`; **~45 AMI OEM handler `.so`s** in `/usr/local/lib/ipmi/` are dlopen'd and register their OEM commands. Group-extension NetFns are served by `libipmidcmi` (DCMI), `libipmihpm` (HPM/PICMG), `libipminmsupport` (Intel Node Manager). Redfish auth reaches the same IPMI user table through `pam_ipmi.so`.

## Active NetFns (live-confirmed)

Enumerated on the running box with the IPMI firmware-firewall command `raw 0x06 0x0a 0x0e <netfn> 0x00`:

| NetFn | Group |
|----|----|
| `0x00` | Chassis |
| `0x02` | Bridge |
| `0x04` | Sensor / Event |
| `0x06` | App (device/BMC/session/firmware-firewall) |
| `0x0A` | Storage (SDR / SEL / FRU) |
| `0x0C` | Transport (LAN / SOL config) |
| `0x30` | **OEM — AMI MegaRAC primary range** (where the OEM handlers below register) |
| `0x3E` | **OEM — secondary AMI range** |

**Not present on this SKU:** the OCP/WCS ranges `0x32/0x36/0x38` (the `g_coreWcsNetFn*` tables exist in the binary but aren't active here), the group-extension OEM/IANA NetFn `0x2E`, and Node-Manager (`libipminmsupport`, disabled with `NM_IPMB_BUS=0xFF` under emulation). The firmware-firewall returns near-full bitmasks for the OEM NetFns (it doesn't granularly firewall OEM), so exact per-command bytes come from the handler tables below, not the live mask.

## OEM commands — 210 handlers across 45 modules (NetFn 0x30/0x3E)

Each `/usr/local/lib/ipmi/libipmiamioem<x>.so` exports its command handlers by name (extracted from `.dynsym`). The names are the OEM command semantics. Security-relevant groups highlighted.

**pwdenc** — `AMISetPwdEncryptionKey` (sets the UserConfig password-encryption AES key)

**backuprestore** — `AMIManageBMCConfig`, `AMIGet/SetBackupFlag` (export/import the whole BMC config)

**restiface** — `AMIRESTinterface`, `AMIGeneratePassword`, `GenerateRandomAlpNumPasswd`, `DeleteUserSession`, `StoreDataInRedisDB` (host-interface / REST bridge — the CVE-2024-54085 neighbourhood)

**fwupdateprctl / dualimg** — `AMIStartTFTPFwUpdate`, `AMIGetTftpProgressStatus`, `AMISet/GetFWProtocol/Cfg`, `AMIDualImageSupport` (firmware update + dual-image control)

**biosremotecontrol / bioscode** — `AMISendToBios`, `AMIGet/SetBiosResponse`, `AMIGetBiosCommand`, `AMIGetBiosCode` (BMC↔BIOS message channel)

**peci** — `AMIPECIWriteRead` (raw PECI passthrough to the host CPU)

**Remotedebug** — `control_remote_debug_server`, `upload_tls_cert`, `get_server_info` (remote debug server)

**acd** — `run_acd`, `control_acd`, `get/set_data_area` (Intel Autonomous Crashdump)

**sessionmgmt / extpriv / hostlock** — `AMIActiveSessionClose`, `AMIGetAllActiveSessions`, `AMIGet/SetExtendedPrivilege`, `AMISet/GetHostLockFeatureStatus`

**ctldbg / ubootmemtest** — `AMIControlDebugMsg`, `AMISetUBootMemtest` (low-level debug hooks)

**media / remotekvm / ris / autovideorcd** — virtual media + KVM redirection (~24 handlers). **raidinfo** — 55 handlers (full RAID/SAS/enclosure management). **Config/services** — ldap, radius, snmp, ntp, timezone, firewall (IPMI firewall), serviceconf, prsvconf, singleport, ad, pamreorder, accessredis. **Protocol** — pldm/pldmcmds, extendedsel, sensorthresholdacrossresets, sd, pwrcons.

Full 210-handler list: `oem-handlers.txt` (workdir). Every handler is `AMI*` — all stock AMI MegaRAC. Exact NetFn/Cmd bytes are in each `.so`'s registration table (reachable via `GetLibMetaInfo` / the `.data` handler-pointer table) — a mechanical per-`.so` parse if a specific opcode is needed.

## HP / HPE / Cray in the IPMI stack?

**None.** Every OEM handler is prefixed `AMI*`; the OEM tables are AMI (NetFn 0x30/0x3E) with dormant OCP/WCS support. No HPE/Cray IANA branch, no iLO handler. The IPMI Manufacturer ID reported by `mc info` is **15370 = GIGA-BYTE**. Consistent with the rest of the firmware: stock AMI MegaRAC on a Gigabyte board; HPE/Cray is packaging + a SKU tag, not BMC code.

Enumerated 2026-07-28 via IPMI firmware-firewall (live) + pyelftools `.dynsym` extraction (static). Byte-level opcode dump per `.so` available on request.
