<!-- html2md:auto source=boxes/irmc-fujitsu/ipmi-path.html source-sha256=2ccc1368a8ff6c43dab46c557f47310d2c6a11df2afcf1a2b242eff57a72e348 body-sha256=a70b391c6a22ef926452a5cb648471cfa288df7c9fa64ab0ec191fcbef6ae0f1 -->

zbmc · Fujitsu iRMC S6

# IPMI listener and response-source trace

An evidence-backed trace from cold boot to UDP/623, through RMCP+ decoding and command dispatch, and onward to the files, in-process state, queues, callbacks, and device interfaces that supply replies.

## Bottom line

The listener is not a separate daemon or proxy. PID 304, `/usr/local/bin/IPMIMain`, owns the dual-stack UDP/623 socket. Its LAN threads decode RMCP/RMCP+, pass decoded IPMI messages through named queues to message-handler threads in the same process, and frame the returned data back onto the original socket.

There is no single response source. Fujitsu replaces AMI's generic Get Device ID handler with an OEM handler; that handler combines one platform-INI byte, hardcoded revision/vendor bytes, and a product ID from an OEM SDR record. Users and channels come from locked objects loaded from INI files. LAN replies deliberately mix configuration with current network state. SEL metadata is computed from a locked repository. Chassis, sensor, and FRU handlers can cross into platform callbacks and hardware-abstraction code. The process has live handles for I2C, KCS, GPIO, IPMB-related queues, `/dev/mem`, and other devices, but their presence does not prove that every command uses them.

## When the listener binds—and when it becomes usable

<table>
<colgroup>
<col style="width: 33%" />
<col style="width: 33%" />
<col style="width: 33%" />
</colgroup>
<thead class="bg-slate-900 text-left text-slate-300">
<tr>
<th class="px-4 py-3">Elapsed</th>
<th class="px-4 py-3">Observed event</th>
<th class="px-4 py-3">What it proves</th>
</tr>
</thead>
<tbody class="divide-y divide-slate-800 bg-slate-900/40">
<tr>
<td class="px-4 py-3 font-mono">+0 s</td>
<td class="px-4 py-3">Run epoch 1790229852: 2026-09-23 23:04:12 PDT</td>
<td class="px-4 py-3">Timing origin for run <code>20260924T060412Z-7a079809-e09d-44c5-8066-fddc2c54f560</code>.</td>
</tr>
<tr>
<td class="px-4 py-3 font-mono">≤51.852 s guest uptime</td>
<td class="px-4 py-3"><code>IPMIMain</code> is already PID 304</td>
<td class="px-4 py-3">The process starts early; listener reachability is not equivalent to process existence.</td>
</tr>
<tr>
<td class="px-4 py-3 font-mono">+194.454 to +218.807 s</td>
<td class="px-4 py-3">Repeated RMCP+ Open Session requests receive no reply</td>
<td class="px-4 py-3">UDP/623 is not externally usable during this interval.</td>
</tr>
<tr>
<td class="px-4 py-3 font-mono">~+410 s guest uptime</td>
<td class="px-4 py-3">Final management-interface/link recovery after address and link bouncing</td>
<td class="px-4 py-3">Network configuration, not process launch, dominates the delay.</td>
</tr>
<tr>
<td class="px-4 py-3 font-mono">+451.541 s</td>
<td class="px-4 py-3">First captured 52-byte RMCP+ Open Session Response</td>
<td class="px-4 py-3">UDP/623 is externally usable by this instant.</td>
</tr>
<tr>
<td class="px-4 py-3 font-mono">+490 s</td>
<td class="px-4 py-3">First complete authenticated RMCP+ health result</td>
<td class="px-4 py-3">Session establishment, authentication, dispatch, and response all work.</td>
</tr>
<tr>
<td class="px-4 py-3 font-mono">+532 s</td>
<td class="px-4 py-3">Run declared READY after stability interval</td>
<td class="px-4 py-3">This is an acceptance-policy timestamp, not listener startup.</td>
</tr>
<tr class="border-t-2 border-cyan-700">
<td class="px-4 py-3 font-mono">41.75 s guest uptime<br />
instrumented run</td>
<td class="px-4 py-3">The tracer starts; UDP6 and TCP6 port 623 are both absent</td>
<td class="px-4 py-3">Run <code>20260924T084004Z-28287029-4051-4120-b5fa-31af60225ae3</code> directly samples <code>/proc/net/udp6</code> and <code>/proc/net/tcp6</code> every 100 ms from the <code>ipmistack</code> startup path.</td>
</tr>
<tr>
<td class="px-4 py-3 font-mono">106.99 s guest uptime</td>
<td class="px-4 py-3">UDP6 inode 7503 appears in state <code>07</code>; TCP6 inode 7504 appears in state <code>0A</code></td>
<td class="px-4 py-3">This is the first bind, bounded to the preceding 100 ms sampling interval—not the stable listener. UDP/623 and listening TCP/623 are created together.</td>
</tr>
<tr>
<td class="px-4 py-3 font-mono">122.45–476.38 s</td>
<td class="px-4 py-3">Repeated socket replacement and loss</td>
<td class="px-4 py-3">Transitions occur at 122.45 (new pair), 123.91 (both absent), 150.50 (new pair), 456.53 (new pair), 469.12 (TCP absent), 470.57 (both absent), 474.63 (new pair), and 476.38 (both absent). Firmware network reconfiguration makes “first bind” an unsafe readiness proxy.</td>
</tr>
<tr>
<td class="px-4 py-3 font-mono">484.42 s</td>
<td class="px-4 py-3">UDP6 inode 20116 and TCP6 inode 20119 appear</td>
<td class="px-4 py-3">This pair remains present through the successful health checks: the final stable bind observed in this run.</td>
</tr>
<tr>
<td class="px-4 py-3 font-mono">+619 s</td>
<td class="px-4 py-3">Instrumented run reaches READY</td>
<td class="px-4 py-3">Authenticated <code>mc info</code> and the required web health check succeed after the final stable bind.</td>
</tr>
</tbody>
</table>

**How to interpret the two runs:** the earlier packet capture establishes first external RMCP+ success at 451.541 seconds. The later guest-side trace establishes first socket appearance at 106.99 seconds, repeated teardown/rebind activity, and the final stable pair at 484.42 seconds. These are different boots: compare the ordering and behavior, not the absolute timestamps. In both, a bound wildcard socket is necessary but is not sufficient evidence of stable remote service.

**This was not stock behavior:** the successful boots use the derived-initramfs `irmc_ipmi_prep` hook. Before `IPMIMain`, it marks the mapped LAN interface enabled/up, sets `AMI_DYNAMIC_LAN_IFC_SUPPORT=1`, and removes `/tmp/BMC1/IPMIConfig.dat` so the process rebuilds its cached configuration. The instrumented run additionally enables `irmc_trace_ipmi`; that tracer observes sockets but does not create them. Do not use the vendor `/etc/init.d/ipmistack restart` path for diagnosis: the experiment made `IPMIMain` SIGSEGV/core and it did not recover until a cold reboot.

## Process and socket ownership

- PID 304 is `/usr/local/bin/IPMIMain`, with 63 threads.
- Thread 369 is `LANIfcTask`; 373 is `LANMonitor`; 374 is `RecvLANPkt`; 375 is `LANTimer`; threads 400–407 are `MsgHndlr`.
- `/proc/net/udp6` shows wildcard port `026F` (623), inode 20142. `/proc/304/fd/52` points to `socket:[20142]`. This directly proves that `IPMIMain` owns the UDP listener.
- The same process also owns a wildcard TCP/623 listener. The working IPMI transport tested here is RMCP+ over UDP/623.

## End-to-end request and response route

1.  **1. Socket creation.** Static analysis follows `LANIfcTask` → `UpdateLANStateChange` → the internal socket initializer in `libipmilan.so.13.8.0`. It calls `socket(AF_INET6, type, protocol)`, applies `SO_BINDTODEVICE` for the configured interface and `SO_REUSEADDR`, then `bind()`s the wildcard configured RMCP port. The datagram socket is the RMCP/RMCP+ path; the second stream socket calls `listen()` and is TCP/623.
2.  **2. Receive thread.** `RecvLANPkt` waits with `select`, receives with `recvfrom`, attaches peer/interface metadata, and posts the record to `/var/LANIfcQ`.
3.  **3. LAN protocol thread.** `LANIfcTask` consumes `/var/LANIfcQ` and calls `ProcessRMCPReq`. That code validates RMCP/RMCP+ framing, session state, sequence numbers, authentication/HMAC, and encryption.
4.  **4. Message-handler handoff.** The decoded IPMI request is posted to `/var/MsgHndlrQ`. The LAN path blocks waiting on `/var/LANResQ`.
5.  **5. Command dispatch.** A `MsgHndlr` thread validates channel, net function, command, request size, feature state, and session privilege. The internal dispatcher uses `GetCmdHndlr` to select a command-table entry and invokes its function pointer.
6.  **6. Return path.** The handler writes completion code and response bytes. `MsgHndlr` posts them to the interface response queue embedded in the request—`/var/LANResQ` for this path. `LANIfcTask` adds IPMI 2.0/RMCP+ framing and authentication, then sends the packet to the original peer with `sendto`.

The `/var/*Q` names are IPC queue endpoints used by threads in the same process. They are not evidence that a separate database server or IPMI daemon constructs the response.

## Command-to-source map

<table>
<colgroup>
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
</colgroup>
<thead class="bg-slate-900 text-left text-slate-300">
<tr>
<th class="px-4 py-3">Command</th>
<th class="px-4 py-3">Handler</th>
<th class="px-4 py-3">Response source</th>
<th class="px-4 py-3">Bus / IPC implications</th>
</tr>
</thead>
<tbody class="divide-y divide-slate-800 bg-slate-900/40 align-top">
<tr>
<td class="px-4 py-3">Get Device ID<br />
<code>mc info</code></td>
<td class="px-4 py-3"><code>OEM_FTS_GetDeviceID</code><br />
<code>libipmipdkcmds</code><br />
ELF 0x26240 · Ghidra 0x36240</td>
<td class="px-4 py-3">Fujitsu's <code>g_Oem_App_CmdHndlr</code> replaces App command <code>0x01</code>. Device ID comes from <code>/usr/local/platform/sdrcfg/system.conf</code>; product ID comes from OEM SDR subtype <code>0x22</code>; all other returned bytes are constants in the OEM handler.</td>
<td class="px-4 py-3">The generic AMI <code>GetDevID</code> and <code>/proc/ractrends/Helper/FwInfo</code> are not on the live path. No host-bus read occurs for this reply.</td>
</tr>
<tr>
<td class="px-4 py-3">Get Chassis Status</td>
<td class="px-4 py-3"><code>GetChassisStatus</code><br />
ELF 0x4b3b8 · Ghidra 0x5b3b8</td>
<td class="px-4 py-3">Loads <code>chassiscfg.ini</code>-derived cached bytes, then invokes registered Fujitsu callbacks: <code>PDK_GetPSGood</code>, <code>PDK_GetLastPowerEvent</code>, and <code>PDK_GetMiscChassisState</code>.</td>
<td class="px-4 py-3">Mixed persistent cache, runtime state, and hardware input. Power crosses a cached host-state bit, configured GPIO, and <code>/dev/miscctrl</code> power-good query. Intrusion also reaches <code>/dev/miscctrl</code>; its final board signal remains unresolved.</td>
</tr>
<tr>
<td class="px-4 py-3">Get Channel Info</td>
<td class="px-4 py-3"><code>GetChInfo</code><br />
ELF 0x40278 · Ghidra 0x50278 → <code>getChannelInfo</code></td>
<td class="px-4 py-3">Reads the locked channel-2 object. The loader and live values trace to <code>/conf/BMC1/LanChcfg1.ini</code>; despite the filename suffix, that section declares <code>ChannelNumber=2</code>. The active-session count is mutable runtime state.</td>
<td class="px-4 py-3">No per-request bus operation or external daemon RPC was found.</td>
</tr>
<tr>
<td class="px-4 py-3">Get LAN Configuration Parameters</td>
<td class="px-4 py-3"><code>GetLanConfigParam</code><br />
ELF 0x60eb8 · Ghidra 0x70eb8</td>
<td class="px-4 py-3">Parameter 4 reads the helper result or cached address-source state; parameters 3, 6, and 12 call <code>nwReadNWCfg_v4_v6</code>; parameter 5 calls <code>nwGetNWInformations</code>; parameter 13 refreshes through <code>nwGetSrcMacAddr</code>. <code>LanIfccfg.ini</code> maps channel 2 to active <code>eth0</code>.</td>
<td class="px-4 py-3">The live DHCP values override stale defaults in <code>lancfg2.ini</code>. <code>libnetwork</code> obtains interface fields with Linux socket ioctls, the default gateway from <code>/proc/net/route</code>, and gateway MAC from the ARP table or an active ARP request.</td>
</tr>
<tr>
<td class="px-4 py-3">Get User Name / Get User Access</td>
<td class="px-4 py-3"><code>GetUserName</code><br />
ELF 0x411d4 · Ghidra 0x511d4<br />
<code>GetUserAccess</code><br />
ELF 0x40e84 · Ghidra 0x50e84</td>
<td class="px-4 py-3"><code>GetUserName</code> copies 16 bytes at user-record offset <code>+5</code>. <code>GetUserAccess</code> packs channel counts and the per-channel user's privilege/callback/link/IPMI flags. Live records match <code>UserConfig.ini</code> and <code>LanChcfg2.ini</code>.</td>
<td class="px-4 py-3">Memory-resident configuration loaded from persistent storage; no per-request SQL, Redis, or other-process lookup was found.</td>
</tr>
<tr>
<td class="px-4 py-3">Get SEL Info / Get SEL Entry</td>
<td class="px-4 py-3"><code>GetSELInfo</code><br />
ELF 0x6e7e0 · Ghidra 0x7e7e0<br />
<code>GetSELEntry</code><br />
ELF 0x6ee3c · Ghidra 0x7ee3c</td>
<td class="px-4 py-3">Reads a mutex-protected repository header. Entry count and timestamps come from shared-SEL or NVR header fields; free bytes are computed as <code>(capacity − entries) × 0x12</code>; operation bits come from command-enable checks.</td>
<td class="px-4 py-3">Repository/NVR-backed cache, not a live sensor-bus transaction for each query. <code>selreclaiminfo.ini</code> corroborates timestamp persistence; its count lagged the live header by one.</td>
</tr>
<tr>
<td class="px-4 py-3">Get SDR Repository / records</td>
<td class="px-4 py-3"><code>GetSDRRepositoryInfo</code><br />
<code>GetSDR</code></td>
<td class="px-4 py-3">Locked in-process SDR metadata and records initialized by <code>SDRInitAgent</code>. Sensor-reading commands can additionally call platform hooks.</td>
<td class="px-4 py-3">The earlier SDR timeout is above the network layer and is consistent with repository/hardware initialization problems; it is not evidence that UDP/623 failed.</td>
</tr>
<tr>
<td class="px-4 py-3">Read FRU Data</td>
<td class="px-4 py-3"><code>ReadFRUData</code> 0x60490</td>
<td class="px-4 py-3">After locking, the generic handler delegates to a platform callback at function-table offset <code>+0x16c</code>.</td>
<td class="px-4 py-3">The observed completion code <code>0x81</code> originates below generic dispatch. The exact Fujitsu callback and its physical FRU backing remain unresolved.</td>
</tr>
</tbody>
</table>

## How to read the provenance tables

Offsets below are offsets in the command payload after the completion code; they are the bytes printed by `zipmi raw`. “Expression” means the exact construction in the selected handler. “Backing source” identifies where the input existed before the request: a constant, a named file/key, mutable process state, a repository record, or a callback boundary. A matching value alone is not treated as causation where the code selects another source.

**Proved**

Wire bytes, handler expression, and source were matched statically and, where possible, against the live guest.

**Boundary**

The handler's helper or callback is identified, but its final kernel/board implementation is not attributed without further evidence.

**Not inferred**

An open device descriptor elsewhere in `IPMIMain` is not assigned to a response unless this command path reaches it.

## Get Device ID: every returned byte

Live data: `06 02 01 00 02 bf 80 28 00 66 06 02 3f 00 53`. This corrects the earlier attribution to AMI's generic `GetDevID`. The generic function would return Device ID `0x20`; the live reply starts with `0x06`. Fujitsu registers command `0x01` in `g_Oem_App_CmdHndlr` to `OEM_FTS_GetDeviceID`, and that function reproduces all 15 bytes exactly.

| Payload offset | Observed / meaning | Exact expression | Backing source |
|----|----|----|----|
| 0 | `06` · Device ID | `getSystemConfiguration(2, &value, 1)` | `/usr/local/platform/sdrcfg/system.conf`, `[systeminfo] device_id=0x06`. The function lazily parses this INI and caches the byte. |
| 1 | `02` · device revision; Device-SDR bit clear | Literal `0x02` | Hardcoded in the Fujitsu handler. |
| 2–3 | `01 00` · firmware revision 1.00 | Literals `0x01`, `0x00` | Hardcoded. These bytes do *not* come from `/proc/ractrends/Helper/FwInfo` on this command path. |
| 4 | `02` · IPMI version | Literal `0x02` | Hardcoded. |
| 5 | `bf` · additional-device-support bitmap | Literal `0xbf` | Hardcoded. |
| 6–8 | `80 28 00` · little-endian IANA `0x002880` = 10368, Fujitsu | Three literal assignments | Hardcoded vendor identity. |
| 9–10 | `66 06` · little-endian product ID `0x0666` | `FtsGetSdrrId()` | OEM SDR subtype `0x22`, record ID `0x0197`, record offsets `+0x0f..+0x10`. The 128-entry OEM-SDR cache is populated while Fujitsu processes type-`0xc0` SDRs loaded from `/usr/local/platform/sdrcfg/SDR.dat`. |
| 11–14 | `02 3f 00 53` · auxiliary firmware-revision bytes | Four literal assignments | Hardcoded. Their more specific Fujitsu meaning is unresolved; the report does not invent one. |

**Why two places say 0x0666:** `system.conf` also contains `system_id=0x0666`, but the Get Device ID product bytes are not read from that key. They are read from the cached subtype-`0x22` SDR record. The equality is corroboration, not the data path.

## Get Chassis Status: cache plus callbacks

Live data: `20 01 41 00`. `GetChassisStatus` first copies four cached bytes under the chassis mutex, then selectively rewrites them. This is the clearest example of a mixed source: persistent/runtime cache provides defaults, while registered platform callbacks can replace current power, last-power-event, and miscellaneous state.

| Offset | Observed / decode | Handler construction | What is and is not proved |
|----|----|----|----|
| 0 | `20` · current power bit 0 = off; restore-policy bits `01` = restore previous state | Clear cached bit 0, call callback-table slot 0, then OR its Boolean result into bit 0; retain cached bits 6:1. | `chassiscfg.ini: PowerState=32` supplies `0x20`. Slot 0 is `PDK_GetPSGood`, which returns `isHostOn() && haGetPowerOk() && haIsSystemPowerOk()`. `isHostOn()` reads cached host-state bit 0; `haGetPowerOk()` samples a configured GPIO with `get_gpio_data`; `haIsSystemPowerOk()` reaches `/dev/miscctrl` command `0x7fff4d09`. Which board rails/signals feed that GPIO and miscctrl result remains unresolved. |
| 1 | `01` · last-power-event bit 0 set | Copy cached byte, then callback-table slot `0x32` replaces it through `PDK_GetLastPowerEvent`. | `chassiscfg.ini: LastPowerEvent=0`, so live `1` is runtime state from the PDK's internal last-event byte, not the file. The setter/event producer remains unresolved. |
| 2 | `41` · misc-state base bit 6 plus intrusion bit 0 | Discard the cached misc byte, add internal drive/cooling bits 2/3 if set, seed `0x40` (or identify-state `0x50`/`0x60`), then invoke slot `0xc1`. | Slot `0xc1` is `PDK_GetMiscChassisState`; it calls `haGetChassisIntrusionRawStatus` and ORs bit 0 when asserted. The raw query reaches `/dev/miscctrl` command `0x7fff4d05`. A clear/re-read path additionally accesses AST2600 addresses `0x1e6e2014`, `0x1e6ef000`, and `0x1e6ef010` through `mmap_read32`/`mmap_write32`. Thus `0x41 = 0x40 + intrusion`; the final pin/CPLD/board signal is still not proved. |
| 3 | `00` · front-panel button-disable bitmap | Fourth byte of the mutex-protected cached chassis status; not rewritten by this handler. | `chassiscfg.ini: FPBtnEnables=0`. No per-request bus access appears in the handler for this byte. |

## Get Channel Info 2: every returned field

Live data: `02 04 01 82 f2 1b 00 00 00`. `GetChInfo` locks the BMC-instance channel table, resolves channel 2 through `getChannelInfo`, and packs the response from that object.

| Offset | Value | Object expression | Initialization / runtime source |
|----|----|----|----|
| 0 | `02` · channel number | Validated request channel | `LanChcfg1.ini: ChannelNumber=2`. The filename is an internal configuration index, not the returned channel number. |
| 1 | `04` · 802.3 LAN medium | `((object[10] & 3) << 5) | (object[9] >> 3)` | `ChannelMedium=4`. |
| 2 | `01` · IPMB-1.0 protocol | `(object[10] >> 2) & 0x1f` | `ChannelProtocol=1`. |
| 3 | `82` · session support 2, active sessions 2 | `((object[11] & 1) << 7) | ((object[10] >> 7) << 6) | ((object[11] >> 1) & 0x3f)` | `SessionSupport=2` is configured. The file has `ActiveSession=0`; live `2` proves the object is updated after load. |
| 4–6 | `f2 1b 00` · protocol-vendor IANA `0x001bf2` | `memcpy(object + 0x13, 3)` | `ProtocolVendorId/0..2 = 242,27,0`. |
| 7–8 | `00 00` · auxiliary channel info | `memcpy(object + 0x16, 2)` | `AuxiliaryInfo/0..1=0`. |

## LAN channel 2: which layer supplies each value

Each raw response begins with parameter-revision byte `0x11`. The live interface mapping is `/conf/BMC1/LanIfccfg.ini`: channel 2 → `eth0`, enabled and up. Crucially, `lancfg2.ini` still contains fallback address `192.168.2.100` and gateway `192.168.2.203`, while the replies contain the active DHCP network. That contrast proves which branches are live-state-backed.

| Selector / raw reply | Displayed value | Handler source | Implication |
|----|----|----|----|
| `4: 11 02` | Address source: DHCP | Depending on dynamic-LAN state, byte zero returned by `nwReadNWCfg_v4_v6` or cached LAN-object byte `+0x1d50`. | `lancfg2.ini` also has `IPAddrSrc=2`; the retained trace does not distinguish the two equal-valued branches for this selector. |
| `3: 11 0a fa 00 2a` | `10.250.0.42` | `nwReadNWCfg_v4_v6`, then copy four bytes from helper-result offset `+0x0d`. | `libnetwork` refreshes this field through an `AF_INET`/`SOCK_DGRAM` socket and `SIOCGIFADDR` (`0x8915`). Active kernel interface state, not the stale INI address. |
| `5: 11 52 54 00 fa 42 02` | `52:54:00:fa:42:02` | `nwGetNWInformations`, then copy result bytes `+1..+6`. | The helper opens an `AF_INET`/`SOCK_DGRAM` socket and issues `SIOCGIFHWADDR` (`0x8927`). The result matches the QEMU NIC configured in `zbmc.box`. |
| `6: 11 ff 00 00 00` | `255.0.0.0` | `nwReadNWCfg_v4_v6`, then copy four bytes from helper-result offset `+0x15`. | `SIOCGIFNETMASK` (`0x891b`) supplies the live `/8` interface mask. |
| `12: 11 0a 00 00 01` | `10.0.0.1` | `nwReadNWCfg_v4_v6`, then copy four bytes from helper-result offset `+0x19`. | `GetDefaultGateway` opens and parses `/proc/net/route`, selects the matching interface with route flags `3`, and copies its four gateway bytes. |

**The helper boundary is closed:** these functions are implemented by `/usr/local/lib/libnetwork.so.13.9.0`, not another daemon. In addition to the captured fields above, selector 13 calls `nwGetSrcMacAddr`: it first searches `/proc/net/arp` for the target IPv4 address and interface; if absent, it opens an `AF_PACKET`/`SOCK_DGRAM` socket and performs an active ARP exchange with `ioctl`, `bind`, `sendto`, `select`, and `recvfrom`. That selector can therefore emit Layer-2 traffic when queried.

## Users: name, existence, and channel privilege

`GetUserName` and `GetUserAccess` do not query an authentication daemon. Under the user mutex they resolve records through `getUserIdInfo`, `getChUserIdInfo`, and `getChannelInfo`.

| Query / raw | Construction | Persistent source | Meaning |
|----|----|----|----|
| User 1 name: 16 zero bytes | `memcpy(response + 1, user_record + 5, 16)` | `UserConfig.ini` record 0: `UserId=1`, `UserName=`, `FixedUser=1`. | A real fixed, enabled null-name IPMI user—not a failed read. |
| User 2 name: `61 64 6d 69 6e` + padding | Same 16-byte copy | `UserConfig.ini` record 1: `UserId=2`, `UserName=admin`, `UserStatus=1`. | The displayed `admin` is a persisted BMC-local account name. |
| User 1 access: `10 42 01 50` | Counts packed from channel object; final byte packs privilege nibble and callback/link/IPMI flags. | `LanChcfg2.ini` channel-user 0: `AccessLimit=0`, callback 1, link auth 0, IPMI messaging 1. | Runtime object says maximum IDs 16, enabled IDs 2, fixed-name IDs 1. The captured file corroborates 2 and 1 but stores `MaxUser=0`; the loader rule producing runtime 16 remains unresolved. |
| User 2 access: `10 42 01 55` | Same packing; low privilege nibble is `5`. | `LanChcfg2.ini` channel-user 1: `AccessLimit=5`, callback 1, link auth 0, IPMI messaging 1. | Privilege `5` is OEM, which is why `ipmitool user list 2` prints “OEM.” User-access initialization and channel-info initialization use distinct indexed configuration structures. |
| User 3: completion `0xcc` | Reject if no valid `getUserIdInfo` record with magic `0x55534552` (“USER”) exists. | Slot 2 has `UserId=0`, blank name, and no valid configured record. Other unused slots look the same, but only ID 3 was retained as a raw request. | “Invalid data field” means no configured user record for that requested ID, not a LAN or authentication transport failure. |

**Exact access-byte packing:** byte 0 is `(((channel[0x1c] & 7) << 3) | (channel[0x1b] >> 5)) & 0x3f` → `0x10` maximum IDs. Byte 1's low six bits are `(((channel[0x1d] & 1) << 5) | (channel[0x1c] >> 3)) & 0x3f` → 2 current IDs; user status `1` supplies the high `0x40`, producing `0x42`. Byte 2 is `(channel[0x1d] >> 1) & 0x3f` → one fixed-name ID. Byte 3 is `(AccessLimit & 0x0f) | (UserAccessCallback << 4) | (LinkAuth << 5) | (IPMIMessaging << 6)`, producing `0x50` or `0x55`.

Password material is not returned by these commands. The firmware separately names `UserEncPswd.ini`, but this trace intentionally follows only fields present in Get User Name/Access replies.

## Get SEL Info: computed repository metadata

Two read-only samples demonstrate the live update: `51 33 00 68 1c f8 5c 6d 38 00 00 00 00 0f` (51 entries, 7272 bytes free), then `51 35 00 44 1c b1 5d 6d 38 00 00 00 00 0f` (53 entries, 7236 bytes free). Two added entries consume `2 × 0x12 = 36` bytes exactly.

| Offsets | Value | Exact construction | Backing |
|----|----|----|----|
| 0 | `51` · SEL version 0x51 | Literal `0x51` | Hardcoded IPMI SEL format version. |
| 1–2 | `33 00` then `35 00` | Little-endian 16-bit entry count from the selected shared-SEL or NVR repository header. | Locked in-process repository state. The nearby file snapshot had `NumRecords=52` while the live header returned 53. File lag, loader adjustment, or differing field semantics are all possible; this trace does not choose among them. |
| 3–4 | `68 1c` then `44 1c` | `min((capacity_entries − current_entries) × 0x12, configured_max)` | Repository capacity/count; each SEL record is 18 bytes. This arithmetic exactly matches both samples. |
| 5–8 | `f8 5c 6d 38` then `b1 5d 6d 38` | Little-endian 32-bit last-add timestamp from repository header offset `+6` (shared mode) or `+8` (NVR mode). | Repository metadata. `selreclaiminfo.ini: AddTimeStamp` is the persistent companion; the precise branch selected in this live process was not captured. |
| 9–12 | `00 00 00 00` · last erase time | Little-endian 32-bit last-erase field | `selreclaiminfo.ini: EraseTimeStamp=0` corroborates the value. |
| 13 | `0f` · all four reported operations supported | Start at zero; OR bits after `GetCommandEnabledStatus` checks for Storage commands `0x41`, `0x42`, `0x45`, and `0x46`. Overflow would set bit 7 separately. | Live command-enable table; no overflow bit was set. |

## Hardware and IPC visible in the process

`IPMIMain` holds descriptors for `/dev/mem`, `/dev/reset`, `/dev/ipmi-kcs1` through `3`, `/dev/i2c-5`, an I2C slave-message queue, `/dev/gpiochip0`, GPIO sysfs values, `/dev/netmon`, `/dev/miscctrl`, and `/dev/ttyS5`. It also owns queues for LAN, KCS, IPMB, UDS, Node Manager, power control, PCIe, CPU-error, and SOL paths.

Console errors prove active attempts to use missing emulated IPMB and eSPI RTC paths. They do not prove that the successful identity, LAN, user, or SEL replies traversed those buses.

## What remains unknown

- The exact instruction-level `bind()` timestamps; the instrumented run bounds each observed socket transition to a 100 ms polling interval, including first appearance at 106.99 seconds and final stable appearance at 484.42 seconds.
- The final board signal behind the configured `haGetPowerOk` GPIO and the kernel-driver-to-pin mapping for `/dev/miscctrl` commands `0x7fff4d09` (system power-good) and `0x7fff4d05` (chassis intrusion). The software and driver boundaries are proved; GPIO/CPLD/eSPI/IPMB attribution beyond them is not.
- The producer that changes Fujitsu's runtime last-power-event byte from persisted 0 to returned 1, and the exact active-session increment site.
- The final physical backend for FRU callbacks.
- The Fujitsu-specific interpretation of auxiliary Device ID bytes `02 3f 00 53` beyond the IPMI “auxiliary firmware revision” field.
- Whether the real RX2540 M7 routes particular callbacks over GPIO, I2C/IPMB, eSPI, CPLD/FPGA, or another controller differently from this reduced QEMU platform.
- Why full SDR enumeration exceeded the client timeout; the transport and dispatcher remained healthy.

## Evidence and reproducibility

Every claim above is tied to one of four evidence classes: retained network/process capture, live read-only IPMI response, live guest configuration capture, or static analysis of a named binary. Live run evidence remains on Debby under `/home/zen/src/oob/zbmc/work/irmc-fujitsu/runs/20260924T060412Z-7a079809-e09d-44c5-8066-fddc2c54f560/`; the field-level evidence was copied into this checkout so it survives loss of the running VM.

<table>
<colgroup>
<col style="width: 50%" />
<col style="width: 50%" />
</colgroup>
<thead class="bg-slate-900 text-left text-slate-300">
<tr>
<th class="px-4 py-3">Evidence</th>
<th class="px-4 py-3">What it establishes</th>
</tr>
</thead>
<tbody class="divide-y divide-slate-800 bg-slate-900/40 align-top">
<tr>
<td class="px-4 py-3"><code>work/irmc-ipmi-analysis/live-field-raw-20260924.txt</code></td>
<td class="px-4 py-3">Fresh raw Device ID, chassis, channel, LAN, user, and SEL replies from <code>10.250.0.42</code>.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>guest-system-conf-live.txt</code></td>
<td class="px-4 py-3">Live <code>system.conf</code>, including <code>device_id=0x06</code>, <code>system_id=0x0666</code>, platform comments, and board configuration.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>guest-field-source-live.txt</code><br />
<code>guest-field-source-focused-live.txt</code></td>
<td class="px-4 py-3">Live channel, interface, LAN, user, and SEL INI data used to compare persistent state with runtime replies.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>live-chassis-channel-config.txt</code><br />
<code>chassis-channel-field-provenance.c</code></td>
<td class="px-4 py-3">Live chassis/channel configuration plus the decompiled callback chain through cached host state, GPIO, <code>/dev/miscctrl</code>, and AST2600 register accesses.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>irmc-fujitsu-sdr.bin</code></td>
<td class="px-4 py-3">The complete 25,952-byte live SDR repository used to verify record <code>0x0197</code>, OEM subtype <code>0x22</code>, and product bytes <code>66 06</code>.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>evidence/irmc-listener-trace-console-20260924.log</code><br />
<code>ipmilan-decomp/{LANIfcTask,UpdateLANStateChange,InitializeSocket-real}.c</code></td>
<td class="px-4 py-3">The complete 100 ms guest-side socket timeline through READY and the static call path that creates, binds, and listens on UDP/TCP port 623. Console artifact UUID: <code>d17fa867-6df9-529e-b1c7-de5d157a7fbb</code>.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>evidence/libnetwork.so.13.9.0</code><br />
<code>evidence/libnetwork-backends.c</code></td>
<td class="px-4 py-3">The exact ioctl, procfs, and active-ARP implementations behind the live LAN response helpers. Registered binary artifact UUID: <code>af62ea9c-7f9a-50a6-95cc-1bc01d94242e</code>; decompilation document UUID: <code>57b05f54-4753-4fb3-b45c-43ffbb1536b7</code>.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>pdk-preprocess-device.c</code><br />
<code>fts-util-device-id.c</code></td>
<td class="px-4 py-3">Decompiled Fujitsu Device ID override, system-configuration parser, and OEM-SDR product lookup.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>msghndlr-channel.c</code><br />
<code>msghndlr-response-sources.c</code></td>
<td class="px-4 py-3">Decompiled channel, chassis, LAN, user, and SEL handlers. Addresses in these files are Ghidra image addresses; tables label ELF and Ghidra offsets separately where both are cited.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>irmc-ipmi-{proc,sockets}.txt</code> on Debby</td>
<td class="px-4 py-3">PID/thread/file-descriptor/socket ownership and IPC queue endpoints.</td>
</tr>
</tbody>
</table>

    2769dd187b7649adb4e7b01af9b4d83fd00ef0e2838a6cc6cc5936a1a448bcf5  host-br-zbmc.pcap0
    5bf47aca53c4375621bf1e4436a0829b07c247253d4ac8bb2c9f8c3872744c94  console.log
    9c0e95d41675315c24c161949a1f83fa77a3e45d4f2e6fe41b92495d056cebae  IPMIMain
    77225865ef06a97260779d2a5a569e57e8b602c397529e8ddd3c81756a365fb1  libipmilan.so.13.8.0
    26231f8e7cb1c7685e3fb7cde0d48dd26bb49aebd836ca0a18bed512d3ecb8c8  libipmimsghndlr.so.13.37.0
    e9e2ecfb37a6844097c028e975aa391ecea00cbd2c216baff488ac41204101ca  libipmistack.so.13.18.0
    35839f7ab40993898666425d50e18654d68791c7dfe3bb5a3c3496e4daa23804  libipmipdkcmds.so.1.53.20
    2ec3621e7d62b028cb78765ceae94f4cbb3dfe03f4ca1e6a658162ebf63d836a  libfts_util.so.1.30.73
    04a13853e4abe56a68587c3279827a7d304fb61d2bbde5b716f588a5999ee1a5  libipmipdk.so.13.10.0
    5a722a9019ed19c8ab1ed7b69bbb35300451af8b2e29b527c949db50f5eaf756  libipmipar.so.13.20.0
    a22b7f6465e258bb15b4a5f6f4da909f1254e6b9bebdea7b564486df760f327e  libfts_SocHalSdUtil.so.13.0.0
    1860eb452ba0a173e68154dc00562664e59331c9e88f4d87ed60933f33c10b6f  libmiscctrl.so.13.3.0
    c95c510443e2eec44b5597ca6a82bbc049662ccefed30d7e41124ce5edf28e56  live-field-raw-20260924.txt
    5fbd894fdce0f7f68d72a833f9688388be6ec40872a2a196f1ac0063bc1a8bb0  guest-system-conf-live.txt
    5fc4ba2bc5af4b56e710652c51d118c16a9febbbd39fd55ff5258c91eec44fe9  guest-field-source-live.txt
    d6a53b896cb27de1b5a7a0ce7897726756e2caf65e5eedf8a60e9361f9127d65  guest-field-source-focused-live.txt
    b1130025144a1e2d51acacca0a8ae512963857cda1fed064f3bea80bf8af54b7  live-chassis-channel-config.txt
    82188f6b3899852b7991216e101253b4537fc73d69e72b7cadc19e86c15e17e1  chassis-channel-field-provenance.c
    a1fcc4367e865b88a25864b8418d22f5c147109c874d4d9f7fb4df6a773b3d07  irmc-fujitsu-sdr.bin
    bf7acb8c15656738cf2f5864c834e8fb16485b2d1b7be7bbd2eae6359880865f  evidence/irmc-listener-trace-console-20260924.log
    468f216bb5d8b68139c800a429e088284ee371cc975854f63c86d99fa873bbbb  ipmilan-decomp/LANIfcTask.c
    c5701e8994a69713092bfd6b611867484baab829a1d7c36da73a890af7e1a206  ipmilan-decomp/UpdateLANStateChange.c
    8688b6b06a52e796a99257a4044edb2fff0fb544a13d4323caf0384e7a734ccb  ipmilan-decomp/InitializeSocket-real.c
    365fc1ae2b07f32e699775dd27a282f5c172bc61bd2642d7506aeeaf48670e9a  evidence/libnetwork.so.13.9.0
    53adb3441e4817e3fca69cc47ad9c1b67e13f33c680d46727c358fc489be4d95  evidence/libnetwork-backends.c

[← Fujitsu iRMC S6 overview](index.md)
