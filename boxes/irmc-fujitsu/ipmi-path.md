<!-- html2md:auto source=boxes/irmc-fujitsu/ipmi-path.html source-sha256=a6a1069e39f0ad0a4a5c3169c04af26bf1ade7c7be60bcfa0b2f800d09878a44 body-sha256=6720e7215163ee99950fb6b38603ef659f7e40d8cc30d27f63042230cbc19deb -->

zbmc · Fujitsu iRMC S6

# IPMI listener and response-source trace

An evidence-backed trace from cold boot to UDP/623, through RMCP+ decoding and command dispatch, and onward to the files, in-process state, queues, callbacks, and device interfaces that supply replies.

## Bottom line

The listener is not a separate daemon or proxy. PID 304, `/usr/local/bin/IPMIMain`, owns the dual-stack UDP/623 socket. Its LAN threads decode RMCP/RMCP+, pass decoded IPMI messages through named queues to message-handler threads in the same process, and frame the returned data back onto the original socket.

There is no single response source. Identity, users, channels, LAN settings, SEL, and SDR are primarily memory-resident structures initialized from persistent configuration or repository files. Chassis, sensor, and FRU handlers can cross into platform callbacks and hardware-abstraction code. The process has live handles for I2C, KCS, GPIO, IPMB-related queues, `/dev/mem`, and other devices, but their presence does not prove that every command uses them.

## When UDP/623 becomes usable

| Elapsed | Observed event | What it proves |
|----|----|----|
| +0 s | Run epoch 1790229852: 2026-09-23 23:04:12 PDT | Timing origin for run `20260924T060412Z-7a079809-e09d-44c5-8066-fddc2c54f560`. |
| ≤51.852 s guest uptime | `IPMIMain` is already PID 304 | The process starts early; listener reachability is not equivalent to process existence. |
| +194.454 to +218.807 s | Repeated RMCP+ Open Session requests receive no reply | UDP/623 is not externally usable during this interval. |
| ~+410 s guest uptime | Final management-interface/link recovery after address and link bouncing | Network configuration, not process launch, dominates the delay. |
| +451.541 s | First captured 52-byte RMCP+ Open Session Response | UDP/623 is externally usable by this instant. |
| +490 s | First complete authenticated RMCP+ health result | Session establishment, authentication, dispatch, and response all work. |
| +532 s | Run declared READY after stability interval | This is an acceptance-policy timestamp, not listener startup. |

**Unresolved exact instant:** this run did not trace `bind()`. It proves that the process exists by 51.852 seconds, that early probes fail through 218.807 seconds, and that the first reply occurs at 451.541 seconds. Because the interface was not usable until roughly 410 seconds, packet capture cannot distinguish an early wildcard bind from a bind performed later. Exact bind time requires a new boot with syscall tracing or frequent guest-side snapshots of `/proc/net/udp6`; no new cold boot was performed for this report.

## Process and socket ownership

- PID 304 is `/usr/local/bin/IPMIMain`, with 63 threads.
- Thread 369 is `LANIfcTask`; 373 is `LANMonitor`; 374 is `RecvLANPkt`; 375 is `LANTimer`; threads 400–407 are `MsgHndlr`.
- `/proc/net/udp6` shows wildcard port `026F` (623), inode 20142. `/proc/304/fd/52` points to `socket:[20142]`. This directly proves that `IPMIMain` owns the UDP listener.
- The same process also owns a wildcard TCP/623 listener. The working IPMI transport tested here is RMCP+ over UDP/623.

## End-to-end request and response route

1.  **1. Socket creation.** `libipmilan.so.13.8.0` creates an IPv4 or IPv6 datagram socket, applies options including `SO_BINDTODEVICE` and `SO_REUSEADDR`, and binds the configured RMCP port.
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
<td class="px-4 py-3"><code>GetDevID</code><br />
<code>libipmimsghndlr</code> 0x48d7c</td>
<td class="px-4 py-3">Mostly cached <code>g_BMCInfo</code>. On first use it opens <code>/proc/ractrends/Helper/FwInfo</code> and parses <code>FW_VERSION=%d.%d.%d[.%d]</code>. A platform callback may adjust manufacturer-specific bytes.</td>
<td class="px-4 py-3">No live host-bus read is present in the generic handler. The observed Fujitsu IANA 10368/product <code>0x0666</code> come from initialized platform state.</td>
</tr>
<tr>
<td class="px-4 py-3">Get Chassis Status</td>
<td class="px-4 py-3"><code>GetChassisStatus</code><br />
<code>libipmimsghndlr</code> 0x4b3b8</td>
<td class="px-4 py-3">Copies cached chassis bytes under a mutex, then invokes platform callbacks for current power and miscellaneous state.</td>
<td class="px-4 py-3">Mixed cache and hardware abstraction. In this image the generic <code>PDK_GetPowerState</code> stub returns zero; miscellaneous state can call <code>haGetChassisIntrusionRawStatus</code>. Exact board-level backing beyond those callbacks is not yet proved.</td>
</tr>
<tr>
<td class="px-4 py-3">Get Channel Info</td>
<td class="px-4 py-3"><code>GetChInfo</code> → <code>getChannelInfo</code></td>
<td class="px-4 py-3">Reads a locked in-memory channel object. Channel records are initialized from AMI IPMI configuration, including <code>LanChcfg*.ini</code> and generated channel structures.</td>
<td class="px-4 py-3">No per-request bus operation or external daemon RPC was found.</td>
</tr>
<tr>
<td class="px-4 py-3">Get LAN Configuration Parameters</td>
<td class="px-4 py-3"><code>GetLanConfigParam</code><br />
0x60eb8</td>
<td class="px-4 py-3">Mixes cached LAN structures with network helpers such as <code>GetEthIndex</code>, <code>GetIfcName</code>, <code>nwReadNWCfg_v4_v6</code>, <code>nwGetNWInformations</code>, and <code>nwGetSrcMacAddr</code>. Startup inputs include <code>/conf/BMC1/LanIfccfg.ini</code>, <code>lancfg*.ini</code>, and <code>LanChcfg*.ini</code>.</td>
<td class="px-4 py-3">Filesystem-backed during initialization, then memory- and kernel-network-state backed. This explains why the reply reflects the active address and MAC.</td>
</tr>
<tr>
<td class="px-4 py-3">Get User Name / Get User Access</td>
<td class="px-4 py-3"><code>GetUserName</code> 0x411d4<br />
<code>GetUserAccess</code> 0x40e84</td>
<td class="px-4 py-3">Reads locked user and per-channel user objects via <code>getUserIdInfo</code>, <code>getChUserIdInfo</code>, and <code>getChannelInfo</code>. Startup configuration names include <code>UserConfig.ini</code>, <code>FixedUserInfo.ini</code>, and <code>UserEncPswd.ini</code>.</td>
<td class="px-4 py-3">Memory-resident configuration loaded from persistent storage. No per-request SQL/Redis/other-process lookup was found in these handlers.</td>
</tr>
<tr>
<td class="px-4 py-3">Get SEL Info / Get SEL Entry</td>
<td class="px-4 py-3"><code>GetSELInfo</code> 0x6e7e0<br />
<code>GetSELEntry</code> 0x6ee3c</td>
<td class="px-4 py-3">Reads a locked in-process SEL repository and NVR-backed structures through <code>GetSDRSELNVRAddr</code>. Named persistent inputs include <code>SEL.dat</code>, <code>selconfig.ini</code>, and <code>selreclaiminfo.ini</code>.</td>
<td class="px-4 py-3">Persistent-file/NVR-backed cache; not a live sensor-bus transaction for each query.</td>
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

## Hardware and IPC visible in the process

`IPMIMain` holds descriptors for `/dev/mem`, `/dev/reset`, `/dev/ipmi-kcs1` through `3`, `/dev/i2c-5`, an I2C slave-message queue, `/dev/gpiochip0`, GPIO sysfs values, `/dev/netmon`, `/dev/miscctrl`, and `/dev/ttyS5`. It also owns queues for LAN, KCS, IPMB, UDS, Node Manager, power control, PCIe, CPU-error, and SOL paths.

Console errors prove active attempts to use missing emulated IPMB and eSPI RTC paths. They do not prove that the successful identity, LAN, user, or SEL replies traversed those buses.

## What remains unknown

- The exact `bind()` timestamp in the existing cold run.
- The final physical source behind every platform callback, especially FRU and chassis signals.
- Whether the real RX2540 M7 routes particular callbacks over GPIO, I2C/IPMB, eSPI, CPLD/FPGA, or another controller differently from this reduced QEMU platform.
- Why full SDR enumeration exceeded the client timeout; the transport and dispatcher remained healthy.

## Evidence and reproducibility

Live evidence is retained on Debby under `/home/zen/src/oob/zbmc/work/irmc-fujitsu/runs/20260924T060412Z-7a079809-e09d-44c5-8066-fddc2c54f560/`. Process/socket captures are under `/home/zen/xcc-shell-audit-20260922/irmc-ipmi-{proc,sockets}.txt`. Static-analysis inputs and decompilations are under `work/irmc-ipmi-analysis/`.

    2769dd187b7649adb4e7b01af9b4d83fd00ef0e2838a6cc6cc5936a1a448bcf5  host-br-zbmc.pcap0
    5bf47aca53c4375621bf1e4436a0829b07c247253d4ac8bb2c9f8c3872744c94  console.log
    9c0e95d41675315c24c161949a1f83fa77a3e45d4f2e6fe41b92495d056cebae  IPMIMain
    77225865ef06a97260779d2a5a569e57e8b602c397529e8ddd3c81756a365fb1  libipmilan.so.13.8.0
    26231f8e7cb1c7685e3fb7cde0d48dd26bb49aebd836ca0a18bed512d3ecb8c8  libipmimsghndlr.so.13.37.0
    e9e2ecfb37a6844097c028e975aa391ecea00cbd2c216baff488ac41204101ca  libipmistack.so.13.18.0

[← Fujitsu iRMC S6 overview](index.md)
