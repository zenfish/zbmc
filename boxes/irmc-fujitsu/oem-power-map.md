<!-- html2md:auto source=boxes/irmc-fujitsu/oem-power-map.html source-sha256=dcec82032cac5b4759e1f88453e300d9b26ae5d00c5702ac645a177a1e1bdf95 body-sha256=0294721b362b98f6a12de748d4570b6d3acfb1c5ff0827105d31d83d2e255c62 -->

zBMC · Fujitsu iRMC S6

# Power-control, telemetry, and transport map

An evidence-backed map of standard and Fujitsu OEM power commands, the interfaces that can carry them, the asynchronous power engine behind them, and the AST2600, GPIO, I²C/IPMB, PMBus, cache, and policy boundaries they reach.

## Bottom line

- **Remote power control is real.** Authenticated LAN requests on normal LUN 0 reach the shared dispatcher. Standard Chassis Control is Operator-level and exposes off, on, cycle, reset, NMI, soft shutdown, and two Fujitsu extensions.
- **The broadest surprise is privilege, not transport.** Fujitsu SCCI power command `NetFn 0x2e / command 0x01` is registered at User privilege. Its selector multiplexes harmless reads and state-changing writes under the same outer privilege gate.
- **KCS is implemented three times.** `/dev/ipmi-kcs1`, `kcs2`, and `kcs3` have active listener threads and feed the same dispatch machinery. This QEMU model lacks the x86/LPC/eSPI master needed to prove a physical host transaction.
- **Command success means acceptance, not completed actuation.** Chassis Control posts work to `/var/ChassisCtrlQ`; a separate power-event engine performs the rail, reset, NMI, or shutdown sequence.
- **The lowest recovered power-button boundary is exact.** A 100 ms simulated button press reaches AST2600 LPC/SWC physical `0x1e789184`, bit 15, through `/dev/miscctrl`. It is a CPU-driven register operation, not DMA and not host-RAM access.
- **NMI is implemented; SMI is not proved.** NMI logical output `0x1b` maps through the RX2540 M7 product table to active-low AST GPIO index `0x69` (105, conventionally GPIO N1) and the GPIO HAL pulse operation. The exported Fujitsu SMI handler is a no-op stub; an LPCSMI pinmux name alone does not establish a usable SMI path.

## Transport reachability

| Path | Power-command status | Evidence and limit |
|----|----|----|
| LAN, LUN 0 | Proved live | Authenticated RMCP+ carried four safe SCCI power reads. Selector `0x1d` also succeeded in a session capped at User privilege. No changing selector was sent. |
| LAN, LUN 3 | Transport proved; handler rejected | A valid RMCP+ LUN-3 request received completion `0xc0`. The packet reached the BMC, but this does not prove execution of the duplicated SMM/MSMM command table. |
| KCS 1–3 | Structural route proved | Three devices, listener threads, request queues, and response queues are live. `KCSIfcTask` preserves NetFn/LUN, marks session type 4, sets current channel `0x0f`, and enters normal dispatch. No emulated host master issued a request. |
| UDS | Structural route proved | `/var/MsgHndlrQUDS1`, `/var/UDS_IFC_Q1`, and `/var/UDS_RES_Q1` are live. Session type 7 is recognized. No UDS power transaction was injected. |
| IPMB | Structural route; peer absent | The shared dispatcher and IPMB queues are active, but QEMU lacks the peer bus/device and logs send failures. Physical IPMB reachability is not proved. |
| Internal PDK API | Code path proved | Requests whose response path is `/var/PDKAPIQ` bypass the configurable command firewall. Handler selection, length checks, and privilege logic still exist elsewhere; this is not a network interface. |

The `0xaaaa` table value is not “LAN-only.” In each 16-byte command record, offset `+10` is a two-bit-per-internal-channel support/configuration mask and offset `+12` is the interface selector. `CheckCmdCfg` resolves channel `0x0f` to a channel object and shifts by the object's internal field at `+4`; it does not shift directly by wire channel number 15. The live KCS object value is still uncaptured, so its final firewall decision has not been experimentally proved.

## Standard Chassis Control

`NetFn 0x00 / command 0x02 / normally LUN 0` is replaced by `OEM_FTS_ChassisControl`. The request is exactly one byte, minimum privilege is Operator (`3`), the channel mask is `0xaaaa`, and the interface selector is zero.

| Action | Meaning | Internal route |
|----|----|----|
| `0x00` | Power down | Queues event `0x08`; policy chooses orderly/agent-mediated or hard-off behavior. |
| `0x01` | Power on | Queues event `0x04`; checks suppression, temperature, shared-rail, and platform state before button actuation. |
| `0x02` | Power cycle | Queues composite event `0x0840`; off and delayed restart are separate phases. |
| `0x03` | Hard reset | Queues event `0x20`, then pulses the reset path when platform policy permits. |
| `0x04` | Diagnostic interrupt / NMI | Queues notify event `0x00800000`, ending at logical output `0x1b` → AST GPIO index `0x69` through the product-specific pulse callback. |
| `0x05` | Soft shutdown | Checks ACPI state and shutdown-in-progress state, then requests a power-button pulse when appropriate. |
| `0x0d` | Fujitsu power-off override | Sends an internal override message; the outer command returns before physical completion. |
| `0x0e` | Fujitsu pulse power button | Sends the internal pulse-button request. |

## Fujitsu SCCI power: User-level mixed read/write surface

The outer command is `NetFn 0x2e / command 0x01`, begins with Fujitsu IANA bytes `80 28 00`, accepts variable request length, and has minimum privilege User (`2`). The fourth byte is a selector. Because read and write selectors share one command-table entry, the table-level privilege check alone does not distinguish them.

### Safe reads proved over LAN

- `0x15`: last power-on reason → one zero byte.
- `0x16`: temporary or last power-off reason → one zero byte.
- `0x18`: four-byte runtime power field → four zero bytes.
- `0x1d`: power-off-inhibit state → one zero byte; independently proved at User session privilege.

### Mutating selectors present at the same outer privilege

- `0x17`: store the next/temporary power reason.
- `0x1b`: set the on/off reason and, for one value, emit a SEL event.
- `0x1c`: set power-off inhibit.
- `0x20`: set the next scheduled power-on time and change the power-saving-prevention reason.

The handler performs no second privilege check. It verifies only that the total request is at least four bytes before the selector switch, but the setters then read fixed fields through offsets `+8` or `+11`. That is a static out-of-bounds-read condition for short requests and a weak validation boundary, although no crash or disclosure was exercised live.

These write selectors were identified statically and were not invoked.

## Fujitsu C0 and D0 power families

The firmware names these “C0” and “D0,” but the wire NetFns are `0x30` and `0x34` with LUN 0. Every recovered entry below is Admin privilege (`4`), variable length, channel mask `0xaaaa`, interface selector zero. Static registration proves dispatch candidates; it does not prove that every blade-oriented handler is meaningful on this RX2540 target.

### NetFn 0x30 (“C0”)

- `00/01` get/set boot-watchdog time. Tiers 0–7 map to 120, 300, 600, 900, 1200, 1800, 3600, or 6000 seconds; the setter also accepts an extended 0–100 minute value.
- `02/03` get/set watchdog enable; the setter accepts only 0 or 1.
- `04/05` get/set watchdog behavior. The setter consumes one byte without a visible value-range check, so the meaning of nonstandard actions remains unresolved.
- `06/07` get/set AC-power-fail restore policy. The setter passes the first byte into `utSetPowerRestorepolicy` without a local range check; this governs whether the host stays off, restores its former state, or powers on after AC returns.
- `0a/0b` get/set reboot retry counter.
- `10/11` get/set the two-byte error-off restart delay in configuration space `0x32`.
- `19` clear power-on-hours by writing `0x02800000` to battery-backed POH state.
- `20/21` get/set whether shutdown should be graceful; `22` reports whether shutdown communication bits `0x0b` are active. The setter reads byte 0 without a local request-length check.
- `51` combines cached/message-LED state with `isHostOn`; `57` reports blade power-good/status; `59` requests host power-off despite its “force server-blade shutdown” name.
- `68/69` get/set compound ASRR policy: watchdog action, restore behavior, timeout tier/extended minutes, retry count, and restart delay.
- `6a/6b` get/set watchdog-timer enable.
- `87` returns a blade-only 14-byte “PowerFull” structure containing blade type, calculated initial/throttled consumption, and memory/PCI/mezzanine counts; it may return command-invalid on this rack server.
- `9b` is misleadingly named `setCPUErrorConfig` but is a no-op success stub: it returns completion 0 without reading the request or changing configuration.

### NetFn 0x34 (“D0”)

- `20/21` set/get iRMC power-control policy. Modes 0–6 include simple and compound policies; mode 4 uses request byte 7 as an array index for four writes without a visible bound check, making this an important memory-corruption test target.
- `22` combines Fujitsu configuration `0x1a00` with Intel Node Manager state to report the actual performance state.
- `23/24` begin/end forced minimum-power mode. Start saves policy, writes configuration `0x1a00=2`, and sets a forced-state flag; end restores the saved policy.
- `27/28` set/get fan duty. Set requires two bytes but visibly consumes only byte 0; the purpose of byte 1 is unresolved.
- `29` ignores its request payload and forces the host power-on LED on.
- `2a` reads a 12-byte power-history sample by class and 16-bit index: minute-class indices 0–1439, a shorter class 0–743, and a platform-sized long-term class. It reads all three fields without a local length check.
- `2c` is stateful and mutating despite the “get counter” name. Mode 0 returns Node Manager counters, clears collection state, and starts a new CPU-throttling averaging interval; paged modes expose saved bytes. When request length is merely greater than 1 it copies 20 bytes from `request+1` without requiring 21 bytes.
- `2d` resolves SDR power-consumption sensor numbers for entity `0x1b` instances 0/1 and entity `0xe0` instance 0.
- `2e` returns a big-endian 32-bit enhanced power budget on blade systems and `0xc1` on non-blade targets.

### Raw CPU bus access: NetFn 0x30 / command 0xe6

This Admin command is a constrained PECI multiple-write/read primitive. The request is `[target, write-length, read-length, write-bytes…]`; it requires cached host-on state, checks that the request contains all declared write bytes, and returns `[completion, read-bytes…]`. Allowed PECI command bytes are `01 61 65 a1 a5 b1 b5 e1 e5 f7`. Several classes retry up to ten times; write classes recalculate their trailing CRC. This is meaningful CPU-package management authority, including power/thermal policy transactions, but it is neither arbitrary PECI nor host-memory access.

## DCMI, Node Manager, PMBus, and stored telemetry

**DCMI:** wire NetFn `0x2c` uses group-extension ID `0xdc`. Fujitsu overrides commands `0x01` and `0x02`; the loaded DCMI library registers the complete table below. Get Power Reading combines a current platform callback with cached minimum, maximum, and average samples plus a timestamp. It is not necessarily a synchronous bus read.

| Cmd | Privilege | Request bytes | Operation and implication |
|----|----|----|----|
| `01` | User | 2 | Get DCMI capabilities. |
| `02` | User | 4 | Get current/cached minimum, maximum, average, timestamp, and sampling state. |
| `03` | User | 3 | Get configured power limit, correction time, sampling period, and exception action. |
| `04` | Operator | 15 | Set the power limit and enforcement behavior; this can arm a later automatic shutdown. |
| `05` | Operator | 4 | Activate or deactivate the configured power limit. |
| `06` | User | 3 | Get asset-tag text. |
| `07` | Operator | 5 | Get DCMI sensor information. |
| `08` | Operator | variable | Write asset-tag text. |
| `09` | User | 3 | Get management-controller identifier text. |
| `0a` | Admin | variable | Set management-controller identifier text. |
| `0b` | Operator | 7 | Set thermal-limit configuration. |
| `0c` | User | 3 | Get thermal-limit configuration. |
| `10` | User | 5 | Get temperature readings. |
| `12` | Admin | variable | Set DCMI discovery/timing configuration. |
| `13` | User | 3 | Get DCMI configuration. |

**Where watts come from:** Fujitsu's platform callback locates an SDR full-sensor record with sensor type `0x0b` and an OEM identity, reads the sensor cache, and applies SDR raw-to-engineering conversion. Longer-window statistics come either from a PMBus power-meter ring buffer or from the firmware's power-history store.

**Power-limit enforcement:** the firmware actively monitors the configured DCMI limit. After the correction interval expires, exception action 1 stores reason `0x21` and requests hard power-off; action 3 stores the same reason and requests chassis soft power-off.

**PSU PMBus:** low-level helpers form `/dev/i2c-<bus>` from the selected PSU record, shift its configured 8-bit address right by one, and issue PMBus reads or writes. Energy reads decode a six-byte response into a 23-bit energy accumulator plus a 24-bit time accumulator and handle wraparound. Higher-level readings normally use caches/ring buffers.

**Node Manager / ME:** a cold-reset helper sends a bridged request with encoded NetFn `0x18`, command `0x02`, and a 400 ms timeout. Runtime text identifies Node Manager slave address `0x2c`. The QEMU environment has no working ME/IPMB peer, so physical execution remains unproved.

## Physical actuation paths

| Operation | Recovered mechanism | Remaining boundary |
|----|----|----|
| Ordinary on/off | `haSystemPowerOn` and `haSystemPowerOff` both call `haSystemPowerOnOff(0,100)`. `/dev/miscctrl` ioctl `0x7fff4d14` sets LPC/SWC `0x1e789184` bit 15, then a kernel timer clears it after 100 ms. | External motherboard net and electrical polarity are not named in the recovered DTB/module. |
| Power-good | ioctl `0x7fff4d09` reads LPC/SWC `0x1e789180`, original bit 30. | Board-level source feeding that SoC indication. |
| Reset | Disables SCU passthrough, drives AST GPIO index `0x79` (121, conventionally P1) low, waits 200 ms, drives it high, waits 200 ms, then restores passthrough. The driver modifies SCU `0x1e6e2000` offsets `0x510`, `0x51c`, and `0x4bc`. | GPIO 121's external motherboard reset net is unlabelled. |
| NMI | Chassis selector 4 → `Platform_HostDiagInt` → queue → notify event `0x00800000` → `haPulseNmiToChipset` → logical output `0x1b`. The product table maps it to active-low AST GPIO index `0x69` (105, conventionally N1) and `socPulseGPIO`; the caller then waits 1 ms. | The external motherboard NMI net, GPIO-HAL pulse width, and final chipset pin remain unlabelled. |
| Hard off | `onUnconditionalPowerOff` obtains a PCH target from runtime platform data and writes in-memory value `0x0200` through `haI2cMasterMW`, retrying the I²C write up to ten times. The live QEMU object contains bus `0xff`, slave `0x00`, so this backend is unconfigured there. | The real RX2540 M7 I²C bus and PCH slave address; QEMU's invalid/sentinel-like values are not evidence for physical hardware. |
| Emergency off | If hard-off fails or power remains, firmware reads LPC/SWC offset `0x188`, ORs `0x7000`, and writes it back: physical `0x1e789188` bits 12–14. Restore clears those bits. | The exact rail-control semantics of those three SWC bits. |
| SMI | `PDK_SMIInterruptChassis` returns zero immediately and touches no hardware. No second SMI implementation was found. | No usable SMI trigger is proved in this image. |

## What is proved, and what is not

- A handler table entry proves that the dispatcher can select a function after its privilege, request-length, channel, interface, and runtime feature checks. It does not prove that the target platform supports the handler's final device action.
- A successful IPMI completion from Chassis Control proves that work was accepted into the asynchronous power machinery. It does not prove that the host rail, reset line, or NMI completed.
- An AST physical register address proves the BMC-side mechanism. It does not, by itself, name the motherboard net connected to that SoC signal.
- The three KCS listeners prove BMC-side readiness. A real server host or a model of the x86 LPC/eSPI master is still needed to prove end-to-end KCS power control.
- The LUN-3 table is named `g_OemSMMCmdHndlr` in this firmware. That name must not be confused with x86 System Management Mode, and the live LUN-3 LAN request was rejected with `0xc0`.

## Evidence

Primary retained evidence is under `work/irmc-ipmi-analysis/oem-power-map/`. No state-changing power, reset, NMI, policy, inhibit, scheduling, watchdog, cap, or restore-policy command was sent during this analysis.

### Core maps and live proof

- `all-command-tables.tsv` — all 160 recovered Fujitsu table records.
- `COMMAND-TABLES-POWER.txt` — exact SCCI, DCMI, C0, D0, and raw PECI layouts, privilege, lengths, mutations, parser weaknesses, and unresolved commands; SHA-256 `bbbaa82ee80a7a219fafb7a66e49ce12e996fa4173e2d90d69a6a29fc2ad56a1`.
- `live-safe-power-queries-20260924.txt` — retained RMCP+ SCCI reads and LUN-3 rejection.
- `guest-transport-focused-live.txt` — live KCS/UDS/IPMB descriptors, queues, threads, and configuration.
- `POWER-BACKENDS.txt` — backend trace and exact AST2600 boundaries.
- `sys-gpio-decomp.c` — product GPIO callbacks and the 28-byte logical-to-AST table containing NMI output `0x1b → 0x69`; SHA-256 `95435eb61479c73423e711d61adf0345ab6c27be4f6bebe4ef4003cc3e2916c1`.
- `live-power-memory-map-20260924.txt` — live library base; SHA-256 `883343e0d01ac7e08a1d26b7384c2a143b65fee7da3d154fd7f1176f9ee97dc3`.
- `live-pch-config-bytes-20260924.txt` — relocated platform-object pointer and QEMU PCH bus/slave bytes `ff 00`; SHA-256 `f71d72b610a20f126ede40d600a39f5c46638461a92eb10891ecdbf1e2ab10d3`.

### Key binary hashes

- `libipmimsghndlr.so.13.37.0`: 26231f8e7cb1c7685e3fb7cde0d48dd26bb49aebd836ca0a18bed512d3ecb8c8
- `libipmipdkcmds.so.1.53.20`: 35839f7ab40993898666425d50e18654d68791c7dfe3bb5a3c3496e4daa23804
- `libipmikcs.so.13.4.0`: a8a22b1479864f2722f24b0247bbc92db04e9e10d39a0d20a6fc1388534ea60c
- `libfts_util.so.1.30.73`: 2ec3621e7d62b028cb78765ceae94f4cbb3dfe03f4ca1e6a658162ebf63d836a
- `miscctrl.ko`: 18e9060390943c98ebca3e98115b726b4a5dffef44a4e748b56204bf63b9039b
- `libfts_sys_0666.so.1.0.0`: b452cedc5382b86f96f9402df396ff2bdb3bd84cf207a5f6af58d34e714a3166

[Back to Fujitsu iRMC S6](index.md) · [IPMI listener and response-source trace](ipmi-path.md)
