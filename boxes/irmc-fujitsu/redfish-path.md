<!-- html2md:auto source=boxes/irmc-fujitsu/redfish-path.html source-sha256=39321b13cf3537b84e21b4f508e200506efda2b0ed9970b13ba0ba6402d46dba body-sha256=5a03a08e59442dc6c3ce6e18e8370a2e1d64954e4361ac581c3eceb8c897a736 -->

zBMC · Fujitsu iRMC S6

# Redfish resource provenance

Where the 274 runtime resources come from, which processes provide their values, and why initialization takes nearly eighteen minutes in the reduced QEMU environment.

## Bottom line

There is no single Redfish database. The service combines static JSON definitions, generated instance files, configuration-store values, local IPMI replies, Redis caches, and compiled Fujitsu provider functions. Several providers are other processes; some of those processes in turn read firmware files, kernel state, buses, or hardware-facing devices.

The complete rotated service log proves that all **274/274** selected resources were constructed. The earlier apparent stop at entry 162 was a status-collector error: it watched the newly rotated log rather than `LogFile.RedfishService.log.1`.

## End-to-end request and value path

1\. HTTP front end

`FTS_WebServer` owns TCP 80/443 and converts HTTP requests into the vendor's internal socket format.

2\. Redfish service

Requests cross `/var/tmp/RedfishServer.sock` to `FTS_RedfishServ`, whose main thread waits in `epoll_wait`.

3\. Definition + map

`*_def.json` defines the route and shape. `GenericMap.json` assigns property placeholders to backends.

4\. Provider

The backend reads config store, invokes a compiled function, sends local IPMI, or queries Redis.

5\. Final source

The provider may end at a file/cache, another daemon, a kernel API, a hardware-facing device, or an unavailable host-side peer.

    TCP 80/443
      → FTS_WebServer
      → /var/tmp/RedfishServer.sock
      → FTS_RedfishServ / DataModel
      → *_def.json + GenericMap placeholder
      → CS | Function | local IPMI | Redis
      → file/cache | IPMIMain | producer daemon | kernel/device/hardware

## The layers and their concrete locations

<table>
<colgroup>
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
<col style="width: 25%" />
</colgroup>
<thead class="bg-slate-900 text-slate-300">
<tr>
<th class="px-4 py-3">Layer</th>
<th class="px-4 py-3">Location / owner</th>
<th class="px-4 py-3">What it supplies</th>
<th class="px-4 py-3">What it does not prove</th>
</tr>
</thead>
<tbody class="divide-y divide-slate-800 bg-slate-900/40 align-top">
<tr>
<td class="px-4 py-3 font-medium text-cyan-300">Resource definitions</td>
<td class="px-4 py-3"><code>/usr/share/redfish/resource/*_def.json</code><br />
283 files</td>
<td class="px-4 py-3">URI templates, resource type, properties, actions, and placeholder expressions; the runtime logged a 274-entry ResourceTree.</td>
<td class="px-4 py-3">A definition file is not a populated resource. File count and ResourceTree-entry count are not assumed to map one-for-one; the exact selection/exclusion rule remains unresolved.</td>
</tr>
<tr>
<td class="px-4 py-3 font-medium text-cyan-300">Schemas</td>
<td class="px-4 py-3"><code>/usr/share/redfish/schemas</code><br />
350 files plus <code>FTSRedfishSchema.zip</code></td>
<td class="px-4 py-3">Redfish/OEM schema material and type validation.</td>
<td class="px-4 py-3">Schemas describe legal representation, not the current machine value.</td>
</tr>
<tr>
<td class="px-4 py-3 font-medium text-cyan-300">Backend map</td>
<td class="px-4 py-3"><code>/usr/share/redfish/GenericMap.json</code><br />
1,329 mapping keys</td>
<td class="px-4 py-3">Routes placeholders to configuration store, compiled functions, IPMI, Redis, or limits.</td>
<td class="px-4 py-3">A “Function” mapping still requires tracing the named function into its library and dependencies.</td>
</tr>
<tr>
<td class="px-4 py-3 font-medium text-cyan-300">Generated instances</td>
<td class="px-4 py-3"><code>/var/tmp/redfish/v1/*_inst.json</code><br />
<code>/var/tmp/redfish/resource_dyn</code></td>
<td class="px-4 py-3">Runtime-selected instance JSON under <code>v1</code>; separate dynamic state/output under <code>resource_dyn</code>.</td>
<td class="px-4 py-3">These files can be materialized output or cache; they are not necessarily the authoritative producer.</td>
</tr>
<tr>
<td class="px-4 py-3 font-medium text-cyan-300">Service IPC</td>
<td class="px-4 py-3"><code>/var/tmp/RedfishServer.sock</code></td>
<td class="px-4 py-3">Request/response channel between the HTTP front end and Redfish service.</td>
<td class="px-4 py-3">It carries results; it is not the origin of DIMM, sensor, SEL, or inventory data.</td>
</tr>
<tr>
<td class="px-4 py-3 font-medium text-cyan-300">Task IPC</td>
<td class="px-4 py-3"><code>/var/tmp/RedfishTaskMngr.sock</code><br />
<code>/var/pipe/rtm_fifo</code></td>
<td class="px-4 py-3">Long-running Redfish task handoff and task-manager communication.</td>
<td class="px-4 py-3">Ordinary property reads need not pass through the task manager.</td>
</tr>
<tr>
<td class="px-4 py-3 font-medium text-cyan-300">Update IPC</td>
<td class="px-4 py-3">SysV queues consumed by <code>selUpdateHandle</code>, <code>csvUpdateHandle</code>, and <code>ielUpdateHandle</code></td>
<td class="px-4 py-3">Asynchronous SEL, CSV, and IEL changes that trigger DataModel refreshes.</td>
<td class="px-4 py-3">The retained snapshot does not identify every queue producer or the exact lock owner during timeouts.</td>
</tr>
</tbody>
</table>

## Backend population

Counts are source declarations recovered from `GenericMap.json`; one property can have Get/Set mappings and the counts are not a count of unique resources.

|                    |     |
|--------------------|-----|
| Function           | 955 |
| CS / config-space  | 856 |
| lowercase function | 28  |
| IPMI               | 15  |
| Redis              | 9   |
| CSLimits           | 1   |

Refresh declarations are 782 `onDemand`, 417 `onEvent`, 119 `onInit`, and 11 with no refresh mode. Here, “CS” is not a direct filesystem read: the recovered `configSpace*` helpers issue Fujitsu OEM local-IPMI requests through the `/var/UDSocket*` family. The valid runtime trace used `/var/UDSocket1`.

## Dispatch implementation

In `libfts_RedfishBackend.so.1.6.168`:

- `DMBackendAccessCS` at `0x96eec`
- `DMBackendAccessFUNC` at `0x97278`
- `DMBackendAccessRedis` at `0x9746c`
- `DMBackendAccessIPMI` at `0x97944`
- `DMBackendHandleRequest` at `0x97aec`

This is the branch point that turns a JSON placeholder into a config-space request, local function call, Redis request, or direct IPMI transaction. On this firmware, config-space helpers also travel over Fujitsu OEM local IPMI rather than reading JSON directly.

## Concrete file-backed examples

Compiled `Function` callbacks are heterogeneous: one may read a file, Redis, local IPMI, a cache library, or synthesize a value. These paths occur in recovered backend code, but apply only to their specific callbacks—not to Redfish globally:

| Redfish value | Callback path | File actually read |
|----|----|----|
| Current BIOS attributes | `Function13` → `rfGetBiosParamFjjAttributes(1)` | `/conf/redfish/bios/CurrentBiosAttributes.json` |
| Pending BIOS attributes | `Function13` → `rfGetBiosParamFjjAttributes(2)`; setter is `Function713` | `/conf/redfish/bios/NextBiosAttributes.json` |
| BIOS registry systems and entries | `Function13` arguments 3 and 4 | `/conf/redfish/registry/BiosAttributeRegistry.json` plus a stripped registry-helper file |
| HTTPS certificate | `Function31` → `rfGetCertificate` → certificate helper | `/conf/fts/www/certs/server.pem`; other callback modes select CA or user-certificate paths |
| BSPBR availability | BSPBR-specific compiled callback | `/conf/fts/bspbr_fru.bin` |
| RAID, BIOS-transfer, product, SEL, and IEL callback state | Separate feature-specific callbacks; not a shared Redfish store | `/conf/RaidCtrlProp.json`, `/conf/RaidConfigSchedTaskInfo.json`, `/var/tmp/BPFJ_recvBiosData.json`, `/var/tmp/productid`, `/var/tmp/sel-log.txt`, and `/var/tmp/iel-log.txt` |

## Worked example: Memory and MemoryMetrics

Entry 161 is the Memory collection, 162 the DIMM instance, 163 the DIMM Metrics instance, and 164 the MemoryDomains collection. Entries 162 and 163 use the same `NEXT_SYSTEM|NEXT_MEMORY` enumeration. `DMItemNextHandler_Memory` calls `memGetMemoryMaxIndex` and then `memGetMemoryModuleStatus` for candidate DIMMs. Those helpers live in `libfts_appHelper.so.1.12.15` and send local IPMI through the `/var/UDSocket*` family to `IPMIMain`; the captured runtime endpoint was `/var/UDSocket1`. The helper argument `0xb8` is the encoded request NetFn/LUN byte (`0x2e << 2`); semantically this is OEM NetFn `0x2e`, command `0xf5`.

| Memory data | Immediate source | Producer / deeper source |
|----|----|----|
| Maximum slot index and module-present/status | Local IPMI request on `/var/UDSocket1` in the captured run | `IPMIMain`; final real-hardware inventory input is below that handler and remains to be proved. |
| DIMM designation and CSS-component flag | Entry-162 `onInit` function calls; OEM local IPMI `0x2e/0xf5` selectors `0x42` and apparently `0x44` | `IPMIMain`; the display name itself is synthesized as `DIMM <index>`. |
| SPD and location data | `/var/tmp/redis.sock`, keys such as `DIMM_%d_SpdData` and `DIMM_%d_LocationData` | `FTS_DimmCacheRefresh` populates Redis using local IPMI, persistent SCCI messages, SPD decoding, and BIOS-supplied data. Its Redis read uses a 1.5-second timeout with one attempt and no retry. Although the seven metrics mappings are declared `onDemand`, the runtime builder did resolve them while materializing the initial instances. |
| AEP/persistent-memory fields | Redis keys `DIMM_%d_AEP_*` | `FTS_DimmCacheRefresh` and `libfts_DimmCache.so.1.0.5`; absent peers/data can leave empty or error results in QEMU. |
| Resource JSON shape | `MemoryCollection_def.json`, `Memory_def.json`, `MemoryMetrics_def.json` | Static vendor files; the DataModel combines them with the enumeration and property results. |

The live guest reported maximum index 40 and status 7 for indices 0–39: exactly forty status requests, not forty-one. The decompiled error path matters: `memGetMemoryModuleStatus` returns 7 for most local-IPMI failures, while `DMItemNextHandler_Memory` excludes only status 9. In this reduced machine, an unavailable status backend therefore makes every candidate slot enumerable rather than absent. The builder creates forty Memory instances and forty MemoryMetrics instances even though QEMU has no real host DIMMs.

Entry 164 also has two static warning signs: no `MemoryDomain_def.json` exists, and `MemoryDomainCollection_def.json` points its item data into `/Systems/$SYSTEM_ID$/StorageServices/$MEMORYDOMAIN_ID$`. This looks vestigial or incomplete, but that is an inference—the missing provider and mismatched path do not by themselves explain the delay.

Entry 165, `/Systems/$SYSTEM_ID$/NetworkInterfaces`, follows a different daemon chain: `DMItemNextHandler_NetworkAdapter` calls `lanc_GetCtrlCount`, which connects to `/var/tmp/lancache.sock`. The server is `FTS_LAN_Cache`. Its static inputs include PNI, persistent SCCI, local IPMI, FRU/OCP, SGPIO, and MCTP over I²C/PCIe using NCSI/PLDM; the exact source remains property-specific and is not attributed without tracing that field.

Boot ordering supports the producer/consumer relationship: Redis starts at S21, `FTS_DimmCacheRefresh` at S70, and `FTS_RedfishService` at S90.

## Process ownership and IPC

<table>
<colgroup>
<col style="width: 33%" />
<col style="width: 33%" />
<col style="width: 33%" />
</colgroup>
<thead class="bg-slate-900">
<tr>
<th class="px-4 py-3">Process</th>
<th class="px-4 py-3">Observed endpoints</th>
<th class="px-4 py-3">Role</th>
</tr>
</thead>
<tbody class="divide-y divide-slate-800 bg-slate-900/40 align-top">
<tr>
<td class="px-4 py-3"><code>FTS_WebServer</code><br />
PID 2170 in the v7 trace VM</td>
<td class="px-4 py-3">TCP 80/443; client side of <code>RedfishServer.sock</code>; SysV queue for single sign-on</td>
<td class="px-4 py-3">Terminates HTTP(S), serializes the request, and forwards it internally. An open port does not mean the DataModel is ready.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>FTS_RedfishServ</code><br />
PID 2120</td>
<td class="px-4 py-3"><code>/var/tmp/RedfishServer.sock</code> (listener inode 17743), <code>/var/DMAccess.lock</code>, SysV SEL/CSV/IEL queues</td>
<td class="px-4 py-3">Owns route construction, property resolution, update handlers, and the central DataModel.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>FTS_RedfishTaskMngr</code><br />
PID 2047</td>
<td class="px-4 py-3"><code>/var/tmp/RedfishTaskMngr.sock</code> (listener inode 16700), <code>/var/pipe/rtm_fifo</code></td>
<td class="px-4 py-3">Executes and tracks long-running task operations.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>IPMIMain</code><br />
PID 3836</td>
<td class="px-4 py-3"><code>/var/UDSocket1</code> (listener inode 34544), internal IPMI queues, KCS devices, I²C, GPIO, <code>/dev/miscctrl</code>, and <code>/dev/mem</code></td>
<td class="px-4 py-3">Answers local IPMI-backed Redfish properties. This is a major boundary: the Redfish PID asks <code>IPMIMain</code>, and <code>IPMIMain</code> may answer from cached state, SDR/sensor repositories, callbacks, or its device-facing descriptors.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>redis-server</code><br />
PID 294</td>
<td class="px-4 py-3"><code>/var/tmp/redis.sock</code> (listener inode 7056)</td>
<td class="px-4 py-3">Holds shared key/value caches. Redis is an immediate value source, not necessarily the original hardware source; the producer of each key must still be identified.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>FTS_DimmCacheRefresh</code><br />
PID 1783</td>
<td class="px-4 py-3"><code>/var/tmp/redis.sock</code>, <code>/var/AepCmdAccessRequestQ0.0</code>, <code>/var/AepCmdAccessResponseQ1783</code>, persistent messages, local IPMI</td>
<td class="px-4 py-3">Produces DIMM/SPD/location/AEP cache entries consumed by Redfish. It does not own the Redis listener; it is a Redis client and cache producer.</td>
</tr>
<tr>
<td class="px-4 py-3"><code>FTS_LAN_Cache</code><br />
PID 1922</td>
<td class="px-4 py-3"><code>/var/tmp/lancache.sock</code> (listener inode 14428), <code>/var/tmp/LCMParam.db</code>, persistent SCCI, local IPMI, FRU/OCP, SGPIO, MCTP/NCSI/PLDM</td>
<td class="px-4 py-3">Aggregates network-adapter inventory for Redfish. Its presence and socket ownership are now dynamically proved; the entry-165 trace did not contact it, so no particular NetworkInterfaces value is attributed to it at runtime in that interval.</td>
</tr>
</tbody>
</table>

The update plane is separate from ordinary value getters. Redfish threads block on SysV queues for CSV, SEL, and IEL updates (retained queue IDs 0, 2, and 4; `ftok` bases `/dev/mtd0`, `/tmp`, and `/conf/fts/iel`). Those messages trigger refreshes, but the retained queue snapshot does not identify the sender PIDs.

## Initialization timing

The complete `LogFile.RedfishService.log.1` records service start at 00:08:17, DataModel initialization at 00:08:19, resource-tree construction at 00:08:53, entry 274 at 00:26:12, and “DM initialized and responsive” at 00:26:13. Resource-tree construction took 1,039 seconds; service start to responsiveness took 1,076 seconds.

| Entry completed | Time spent before it | Interpretation |
|----|----|----|
| 55 · EventService | 114 s | Backend initialization/retry delay; not a static JSON parsing cost alone. |
| 163 · DIMM Metrics | 137 s in the untraced reference boot; 119.881 s in the traced run | The vendor log line marks the beginning of the entry's work. The valid trace proves forty template reads, forty generated files, and 280 Redis connections before entry 164 begins. |
| 180 · Temperatures collection | 75 s | Missing/slow sensor-side providers in the reduced platform. |
| 182 · FirmwareInventory | 333 s | Strongly correlated with six failed SEL `UsedIn` updates at one-minute intervals and shared DataModel locking. |

The live descriptor capture proves that `FTS_RedfishServ` had `/var/DMAccess.lock` open. It does not prove which thread held the advisory lock during the later minute-scale stalls, or whether lock contention caused those intervals. The valid trace covers only entries 162–170, so entries 180–182 still require a trace over that later interval.

## Final cold acceptance with static management networking

The 2026-09-24 acceptance boot combined the dual-FMC Redfish repair with a vendor-owned static management address. Before `IPMIMain` started, LAN object 0 was set to `IPAddrSrc=1`, `IPv4_Enable=1`, `IPv6_Enable=0`, `10.250.0.143/8`, and gateway `10.0.0.1`. Fujitsu then generated a static-only `/conf/interfaces` file. The address and authenticated IPMI survived both the initial reload and the delayed reload at guest uptime 570–606 seconds.

A packet capture spanning cold boot, both LAN reloads, and Redfish completion matched DHCPv4 ports 67/68 and DHCPv6 ports 546/547. It remained the 24-byte pcap header with no packet records. At guest uptime 1782.40, neither `udhcpc` nor `dhcp6c` was running and neither PID file existed.

| Acceptance check | Result |
|----|----|
| Redfish resource tree | `274/274`, followed by `DM initialized and responsive` |
| ServiceRoot | HTTP 200 with `RedfishVersion` |
| Managers without credentials | HTTP 401 |
| Managers with the default lab credentials | HTTP 403 with `PasswordChangeRequired`, the expected first-login boundary |
| Fujitsu Web UI | HTTP 200 |
| RMCP+ IPMI after Redfish completion | Authenticated; manufacturer 10368, product `0x0666` |

## What is and is not dynamically proved

The retained logs and `/proc` snapshots prove timing, process/socket ownership, thread wait states, file descriptors, and named IPC endpoints. Earlier files named `strace-live-transcript.txt` and the two ftrace transcripts contain no syscall records; they must not be cited as tracing evidence.

Three early-boot capture attempts produced no syscall artifact, for now-useful reasons: late boot removed files under `/tmp` in v4; the platform root makes `/home` read-only in v5; and late boot also swept `/var/tmp` in v6. More importantly, the original 724,484-byte tracer was an obsolete pre-EABI5 ARM binary: its apparent attach marker was emitted before execution was verified, while a guest smoke trace actually exited 4 and created no file. The consoles are preserved as failure evidence.

The valid v7 capture used a newly cross-built, statically linked ARM EABI5 soft-float `strace 6.13`. A native guest smoke test produced 181 syscall lines before it attached to the stable `FTS_RedfishService` daemon with parent PID 1. The trace begins partway through entry 162 at DIMM 29, covers entries 163–165 completely, and continues through entry 170. It therefore cannot dynamically recount the first 29 DIMM status transactions; the exact forty-request result remains proved by the complete service log plus the recovered loop bounds.

<table>
<colgroup>
<col style="width: 33%" />
<col style="width: 33%" />
<col style="width: 33%" />
</colgroup>
<thead class="bg-slate-900">
<tr>
<th class="px-4 py-3">Captured interval</th>
<th class="px-4 py-3">Actual operations</th>
<th class="px-4 py-3">Meaning</th>
</tr>
</thead>
<tbody class="divide-y divide-slate-800 bg-slate-900/40 align-top">
<tr>
<td class="px-4 py-3">Tail of entry 162 → log entry 163</td>
<td class="px-4 py-3">Eleven generated <code>Memory/{29..39}_inst.json</code> writes; ten complete <code>Memory_def.json</code> cycles; 470 successful connections to <code>/var/tmp/redis.sock</code>; eleven builder-thread connections to <code>/var/UDSocket1</code>.</td>
<td class="px-4 py-3">The per-DIMM resource builder resolves cached fields during initial materialization. The ten fully captured definition cycles account for exactly 47 Redis connections each.</td>
</tr>
<tr>
<td class="px-4 py-3">Entry 163 → entry 164<br />
<code>119.881 s</code> under tracing</td>
<td class="px-4 py-3">Forty opens of <code>MemoryMetrics_def.json</code>, forty generated <code>Metrics_inst.json</code> writes, and exactly 280 successful Redis connections: seven per DIMM. Every captured metrics JSON showed <code>BlockSizeBytes:null</code>.</td>
<td class="px-4 py-3">This closes the former 21-second unknown: the interval is metrics-instance construction and cache lookup, not <code>MemoryDomains</code>. The log's “entry processed” line precedes that entry's work.</td>
</tr>
<tr>
<td class="px-4 py-3">Entry 164 → entry 165<br />
<code>2.675 s</code></td>
<td class="px-4 py-3">Four builder-thread connections to <code>/var/UDSocket1</code>; one read of <code>MemoryDomainCollection_def.json</code>; one generated <code>MemoryDomains_inst.json</code> containing zero members.</td>
<td class="px-4 py-3">The feature materializes as an empty collection in this VM. No Redis or LAN-cache connection occurred in this interval.</td>
</tr>
<tr>
<td class="px-4 py-3">Entry 165 → entry 166<br />
<code>0.239 s</code></td>
<td class="px-4 py-3">Only service-log file operations were observed; no <code>/var/tmp/lancache.sock</code> connection occurred anywhere in the capture.</td>
<td class="px-4 py-3">The statically recovered <code>lanc_GetCtrlCount</code> path was not exercised through a visible socket here—either the empty collection short-circuited it or the value was already in-process. Static capability is not promoted to runtime fact.</td>
</tr>
</tbody>
</table>

Across the 3637-line capture there were 750 successful Redis connections and 42 attempts to `/var/UDSocket1`. Ten of the local-IPMI connections during the metrics interval came from the separate SEL-update thread, so they are not attributed to metrics construction; the table counts only builder-thread calls where stated. Redis payload keys are not visible because the initial syscall filter omitted `readv/writev`, which the client library uses.

The Redfish service snapshot had no persistent direct hardware `/dev/*` descriptor other than its console. That supports the provider/daemon architecture, but it does not rule out short-lived device opens or device access inside another PID.

## Relevant DataModel symbols

- `DMReadFile2Json` · `0xa818`
- `DMUpdateOnDemandValues` · `0xb4a4`
- `DMCreateResourceInstFile` · `0x138bc`
- `DMGetResourceProperties` · `0x1450c`
- `GetRedfishResourceDefFile` · `0x147f4`

Offsets are from `libfts_RedfishDataModel.so.1.6.107`.

## Evidence retained on Debby

- `/home/zen/src/oob/zbmc/work/irmc-redfish-integration/LogFile.RedfishService.log.1` — complete 274-entry initialization log; SHA-256 `049f39a574a89edb89944330e05a98cd2ba0f69c94724edbbed9aa2f71480c05`.
- `provenance.txt` — live process, thread, descriptor, socket, and queue snapshot.
- `work/irmc-redfish-integration/provenance-live.out` — v7 live ownership snapshot proving the Redis, LAN-cache, local-IPMI, Redfish-service, task-manager, and HTTP-front-end PIDs and socket inodes; artifact UUID `73fc77c1-8ed3-5101-9f27-0a5389f53db1`; SHA-256 `55538b247fbb62eeeb1fcddd11a05c50956331a6347488c59840bc967490ee9d`.
- `redfish-state.txt`, `redfish-logs.txt`, and `completion.txt` — retained service state and log exports.
- `work/irmc-redfish-integration/redfish-key-v7.strace` — valid entry-162-through-170 syscall trace; 3637 lines, 393,415 bytes; artifact UUID `71962ae0-3955-5c2a-a449-4ae8445e8e15`; SHA-256 `87e4ad1415021f2e001df4bc11cd7aacde35d1c6fd2ce6e8b41c22c0e4e561fc`.
- `work/irmc-redfish-integration/strace-armel-eabi5-static` — stripped static ARM EABI5 soft-float `strace 6.13`; artifact UUID `8dbc6b4f-9d0c-56f3-ae21-8201f14276c9`; SHA-256 `927394fa2bcdb0b6c5b726968199a1403f7a522ac75d19dc500ccd57bc21a112`. Its native guest smoke trace returned status 0 and produced 181 lines.
- `work/irmc-static-acceptance/` — final cold static-network and Redfish acceptance. Key artifacts are `console.log` (SHA-256 `8d2d0bfacfda8b262cd0f89666f3509054ea9f6d9848c1724c412acf201a6218`), the empty all-DHCP capture `dhcp-watch-all.pcap` (SHA-256 `704e5e5b3234433c01fcfd1b20a306e77e985038120492dc53965c3edd38a4ea`), and `guest-final-acceptance.out` (SHA-256 `8895478e147eac0f56550655c1db59db36443992b6220ec01f833aa7005ca090`).
- The superseded 724,484-byte tracer had SHA-256 `409269dd9e97bf07061cd7d7ba40fe5d3e9b66418dfb58f488ff45066c592741`; it is retained only as evidence of the pre-EABI5 incompatibility and was not used for the valid trace.
- `work/irmc-redfish-static-analysis/GenericMap.json` and `resource-definitions.txt` — retained backend map and the 283-file definition inventory used for the independently repeated counts.
- Firmware filesystem and unpacked analysis trees; primary binaries include `libfts_RedfishDataModel.so.1.6.107`, `libfts_RedfishBackend.so.1.6.168`, `libfts_appHelper.so.1.12.15`, and `libfts_DimmCache.so.1.0.5`.

<!-- -->

    2d47a0bc5ee05b1e7a94472a00bbc336814994f4160c54d922d823eabc8b0524  GenericMap.json
    93850417a9c552b4a452d3a8fb5e621943fc92a18272817878eb3c65a4ce3691  libfts_RedfishDataModel.so.1.6.107
    76d85c248c85d792d30a35fd0cbb682074c669215b92dc6146d90e9c3f96bda9  libfts_RedfishBackend.so.1.6.168
    fac61022ba2b08f57e24ff1132564143c1366c1ed6d4be91175f770568212966  libfts_appHelper.so.1.12.15
    7fccf5249607fab8b8449208726ad973cb931ca10f9df6a410c714ee0a236056  libfts_DimmCache.so.1.0.5
    242bbc216e2d900acd7f09395dcb5ac1156d8fec1b818bf7e53a78e5d3044d4d  FTS_DimmCacheRefresh
