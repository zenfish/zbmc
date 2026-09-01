<!-- html2md:auto source=docs/why-bmc-virtualization-is-hard.html source-sha256=78ca1b1809c8b4322096c3e67c445ddf111ae1a1e56674fa3a99d3e6ca879695 body-sha256=7fbeb13ad5c2e3c61ae05b692d27ce48ab3b2da65ebf1f1d4a90410f1801d198 -->

## Why, oh Why?

BMC firmware is specialized. It's built for a particular SoC and motherboard, not for a generic virtual computer. It expects - knows - particular boot ROMs, flash geometry, device trees, watchdogs, sideband networking, persistent configuration, and management peripherals that QEMU may understand, model differently, or not model at all.

Part was - ahem - self-inflicted. The zoo began as a set of (mostly successful) experiments: mutable QEMU builds, host-specific paths, old processes, implicit network assumptions, sparse evidence, and status output that confused startup history with current health. Turning those experiments into a reproducible tool exposed seemingly every conceivable accidental dependency (I'm sure there are many more, lol.)

**The key:** a booting image is not necessarily a working BMC. Boot, service startup, protocol reachability, authentication, and useful command behavior are separate acceptance stages.

## Six boundaries had to hold

1.  1Firmware extraction
2.  2Boot and storage
3.  3Emulated devices
4.  4Network path
5.  5Vendor services
6.  6Functional probes

A failure at any boundary often looked identical from outside: a long timeout. Progress required preserving serial output and testing each boundary independently rather than interpreting every timeout as one problem. It also drove an at least conceptual monitoring and instrumentation ideology that tried to track and identify issues at each of the levels.

## The inherent problems

Firmware and boot

### Vendor images are board appliances

A vendor image may contain SPL, U-Boot, a signed FIT, OP-TEE or root-of-trust stages, kernel, device trees, read-only root filesystems, writable configuration partitions, and recovery images. QEMU often cannot complete the physical secure-boot chain, so the usable path is a direct-kernel boot with carefully extracted kernel, DTB, initramfs, flash, or SD/eMMC images.

Small mismatches are fatal: a forced kernel command line ignores `-append`, an SD image must be padded to a power of two, an eMMC root partition must retain its exact GPT index, and AMI MTD partition names must match scripts inside the firmware.

Emulated hardware

### QEMU is part of the hardware contract

The zoo spans ARMv7 ASPEED and NPCM750 guests plus AArch64 NPCM845. Each needs the correct system emulator, board model, ROM data, UART order, storage controller, and NIC. A QEMU version string alone does not identify those behaviors.

Two emulator defects became release artifacts: recycled FTGMAC receive descriptors could panic Supermicro X10 after normal browser traffic, while iDRAC10's USB NIC needed high-speed descriptors and endpoint-aware packet framing. The complete rationale is in [Why zbmc Ships Multiple QEMU Builds](why-multiple-qemu-builds.md).

Network last mile

### A visible NIC was not necessarily a usable NIC

BMC NICs frequently depend on NC-SI sideband behavior rather than ordinary Ethernet. QEMU's FTGMAC model handles NC-SI internally, so an external responder cannot repair an incompatible guest driver. MegaRAC's newer kernel negotiates; Advantech's older kernel rejects the observed response, and its current acceptance remains console-only.

Other boxes required USB networking, firmware-derived MAC addresses, loopback aliases, TAP bridges, or QEMU user networking. TCP services could work while RMCP+ UDP failed. A path working from the QEMU host did not prove that a browser on another machine had a route to it.

Vendor userland

### Services expected the missing motherboard

Management daemons depend on D-Bus, socket activation, configuration databases, users, symlinks, sensor inventories, IPMB buses, and hardware interfaces. A daemon could bind UDP/623 yet never answer an IPMI command, or an HTTPS listener could exist while the vendor Web-UI and Redfish had different health.

Some services needed bounded emulation-specific preparation: seed configuration, disable impossible hardware interfaces, create runtime directories, or start the right socket-activated process. These changes had to preserve the vendor protocol path rather than replace it with a superficial port listener.

Timing and state

### Slow TCG execution exposed races

Cold boots took minutes on a four-core host. Single-vCPU emulation exposed D-Bus and service-ordering races that physical hardware rarely presents. A fixed readiness deadline could expire even though QEMU and the guest continued toward healthy service.

Warm snapshots made some boxes reliable, but they were not universal. Migration streams depend on QEMU device-state layout, storage must match captured RAM, and iDRAC9's USB NIC does not recover correctly after restore.

Observability

### The useful failure was usually inside serial output

Without an always-on serial log, a failed network probe only said that a service was not reachable. It did not reveal whether the kernel panicked, a getty needed a newline, a database lookup failed, or a watchdog reset the guest.

Per-run console logs, event timelines, packet captures, debug traces, and exact commands turned transient failures into evidence that could be compared across emulator builds.

## What we supplied, and what that proves

The decisive distinction is not simply real versus fake. It is whether the vendor component remained in the path while we supplied its missing environment, or whether we replaced the component itself. The first can tell us something meaningful about the vendor component. The second proves only the integration around our substitute.

| Technique | What zbmc actually supplied | What remained real | Evidence boundary |
|----|----|----|----|
| Model the expected board | QEMU machine and device changes supplied missing SoC behavior; iDRAC10 also received a USB-network device-tree overlay. | The vendor kernel, drivers, and userland consumed the modeled devices. | Validates those components against the model, not against every electrical or timing property of the physical board. |
| Reconstruct persistent board state | MegaRAC received its factory `/conf` tree and `/conf/BMC` platform link. iDRAC9 and iDRAC10 received configuration-database defaults, writable persistence paths, a root IPMI identity, channel access, and network values normally created elsewhere in the appliance. iDRAC9 also stages borrowed platform topology files so its sensor and I2C consumers do not crash. | Vendor configuration managers and management daemons read the reconstructed state through their normal database and D-Bus paths. | Exercises real consumers with synthetic initial state; it does not prove the missing factory-provisioning, credential-vault, or topology-generation paths. |
| Disable hardware that does not exist | The X14 DTB disabled absent NC-SI NICs. MegaRAC configuration disabled serial, SOL, BT, SMM, SMBus, IPMB, or KCS paths that otherwise left corrupt interface tables or restart loops. | The remaining vendor stack, including its LAN management path, continued to run. | Proves only the retained interfaces. A disabled peripheral is explicitly outside the virtual box's claim. |
| Rebuild startup orchestration | Scripts created runtime directories, mounted writable state, started D-Bus and object mappers in order, and supplied socket-activation file descriptors. The X14 service boot starts selected vendor daemons without the full vendor systemd sequence; iDRAC10 pre-binds the IPv6 UDP/623 socket that `fullfw` expects on file descriptor 3. | Named vendor daemons remain in the path where stated: `fullfw`, `ipmid`, `netipmid`, and `bmcweb`. | Useful evidence about those daemons, but not proof that the original boot ordering, watchdogs, or complete service graph work unchanged. |
| Shim a missing dependency or behavior | iDRAC10's fake journal accepts and discards the logging connection required by `dbus-broker-launch`. Its preload shim replaces broken System V shared memory and semaphores with file-backed state; it also injects user lookup, privilege, HMAC-key, power and health state, and selected IPMI command handlers. | `cfgmgrd` and `fullfw` still parse requests and run the vendor transport and dispatcher around those interposed behaviors. | This is hybrid vendor-backed IPMI, not unmodified Dell IPMI. It cannot establish Dell's storage, concurrency, authorization, state reporting, or every command path. The bounded release contract passes, but its fidelity claim remains partial. |
| Replace operator access | MegaRAC-HPE injects Dropbear and `mini_telnetd`, redirects its missing SMASH program to `/bin/sh`, clears the emulated `sysadmin` password, and provides a direct root console. | These paths provide access to the running vendor userland and its real management daemons. | They prove neither vendor SSH or SMASH behavior nor the appliance's normal authentication policy. |
| Align synthetic identity | NVIDIA's QEMU NIC is configured with the MAC address that its firmware adopts during boot; otherwise user-network forwards remain attached to the discarded DHCP identity. | The firmware still configures the interface and serves SSH, IPMI, Redfish, and the Web-UI. | The alignment is verified, but the tracked files do not establish where the firmware obtained that value. Direct-L2 use still requires isolation to avoid duplicates. |
| Replace an endpoint | iDRAC10's Apache setup serves a static JSON document at `/redfish/v1/` because the vendor Redfish dependency graph is not running. | Vendor Apache and TLS terminate the request; the Redfish response does not come from the vendor Redfish service. | Proves HTTPS routing to a synthetic ServiceRoot only. It is labeled static and cannot establish vendor Redfish behavior. |
| Keep a no-mock control | The upstream OpenBMC box boots its complete flash image. zbmc only retries the image's own `phosphor-ipmi-net@eth0.socket` after SSH becomes reachable. | Its tested SSH, IPMI, Redfish, and Web-UI services remain upstream components without synthetic databases or replacement endpoints. | This clean baseline helps distinguish general QEMU or orchestration failures from the compatibility work required by vendor appliances. |

**Working rule:** preserve the vendor component whenever possible and supply only the narrowest missing dependency. When a component or behavior is replaced, label the substitute and exclude the replaced behavior from the acceptance claim.

## The self-inflicted problems

| Inherited condition | Why it hurt | Replacement | State |
|----|----|----|----|
| Known-good local QEMU binaries | Their version output did not disclose patches, ROMs, or build provenance. | Pinned recipes, manifests, hashes, Docker package, machine discovery, and QMP smoke tests. | Corrected |
| Host-specific paths and setup | A fresh clone could build firmware yet fail because QEMU or zipmi was absent. | `build.sh` provisions and validates the packaged runtime before reporting success. | Corrected |
| Status mixed history with health | A timed-out startup watcher looked like a crashed or currently unhealthy BMC. | Separate QEMU state, startup-watch outcome, and live functional Health probes. | Corrected |
| Fleet-wide parallel probing | Eight concurrent SSH, HTTPS, and RMCP+ checks created false failures on the test host. | Sequential fleet status by default; explicit `--fast-check` for parallel probes. | Corrected |
| Direct LAN assumptions | A bridge that worked on Debby could not carry an arbitrary guest MAC and address on a cloud network. | X10 defaults to QEMU user networking; direct TAP mode is explicit. | Corrected |
| Process-local forwarded ports | Detached watchers reselected ports after QEMU occupied the originals. | Recover active forwards from the running QEMU command before selecting new ports. | Corrected |
| Docker attached to SSH lifetime | Terminal hangup delivered SIGHUP through the container runtime and killed QEMU. | Detach the container, wait independently, ignore HUP, and retain explicit interrupt cleanup. | Corrected |
| iDRAC10 serial shell called SSH | The operator was attached to the PID 1 shell; exiting it panicked the guest kernel. | Use authenticated TCP/22 for `ssh`, reserve serial for `console`, and supervise the debug shell. | Corrected |
| Unmonitored parallel investigations | Work appeared to stall, conclusions moved ahead of preserved evidence, and the operator had to request progress repeatedly. | Give independent tracks explicit checkpoints, report concrete evidence, label inference, and commit each verified logical unit. | Process rule |
| Fallback process discovery | A fresh checkout could adopt an older QEMU process when its host-forward signature matched. | Current run evidence records PID plus process-start identity and refuses unmanaged reuse or stop. | Corrected |

## Approaches that failed

### Treat a boot marker as readiness

A kernel or shell can be alive while IPMI, SSH, Redfish, and the vendor UI are absent. Acceptance moved to authenticated functional probes.

### Use one generic service policy

The boxes expose different real capabilities. Each descriptor now declares its health denominator; undeclared or disabled functions are N/A.

### Interpret timeout as death

The original deadline is historical. Live QEMU and service probes determine current health.

### Assume a listening port is a service

UDP/623 or TCP/443 can be bound while requests fail. Probes perform authentication and useful protocol operations.

### Treat Redfish and Web-UI as one feature

They may share HTTPS but have different routes, dependencies, and failures. They are checked independently.

### Use snapshots as a universal cure

Snapshots preserve races only when RAM, disk, device state, and network migration all remain compatible.

### Infer requirements from one successful binary

A known-good artifact is not proof that its version is required. Advantech's separate QEMU 10 build is documented accordingly.

### Debug without preserving the run

Uncaptured console output and commands made failures impossible to compare. Every launch now creates an evidence directory.

### Force a fully static QEMU build

Debian lacked the required static pixman, mount, and slirp library closure. Exact dynamically linked binaries inside a pinned Docker image provided the portable boundary instead.

### Put a fake NC-SI responder outside QEMU

This remained an abandoned idea, not an implementation. QEMU consumes the NC-SI traffic inside its FTGMAC model before the netdev, so an external responder cannot repair the incompatible Advantech path.

## What ultimately worked

### Per-box contracts

Each descriptor owns its machine, boot method, network, credentials, probes, expected services, and timing policy.

### Exact emulator artifacts

Paths, versions, machines, ROMs, patches, and hashes are validated before firmware launch.

### Functional health

Health reflects commands that work now, not only ICMP, open ports, or old startup state.

### Permanent console evidence

Verbose status exposes the serial log and exact `tail -f` command for the active run.

### Causal comparison

Working and failing binaries, packets, descriptors, and service traces were compared before assigning root cause.

### Evidence labels

Verified, decoded, historical, inferred, and unknown claims remain distinct instead of becoming folklore.

## Current fleet boundary

These are the release acceptance results, not claims of perfect physical-hardware equivalence.

| Box | Accepted function | Result | Measured time |
|----|----|----|----|
| openbmc | ICMP, SSH, IPMI, Redfish, Web-UI; cold timing remains load-sensitive | Pass | 4m32s |
| nvidia-obmc | ICMP, SSH, IPMI, Redfish, Web-UI; cipher 17 only; modeled FRU MAC requires isolation on direct L2 | Pass | 5m21s |
| supermicro-x14 | ICMP, SSH, IPMI, Redfish, Web-UI; service-oriented boot is not full vendor parity | Pass | 3m31s |
| supermicro-x10 | SSH, IPMI, Redfish, Web-UI, 60s stable hold; cold readiness remains host/load-sensitive | Pass | 2m38s user-net; 3m11s direct |
| idrac9 | ICMP, SSH, IPMI, vendor Web-UI; Redfish unavailable; USB-net warm restore is network-dead | Pass | 10m31s |
| advantech-asmb787 | Serial login; external networking remains unresolved, with the old NC-SI path the leading explanation | Console pass | 9m38s |
| idrac10 | ICMP, SSH, retained IPMI through vendor `fullfw` with auth, state, and selected command interposition; static Redfish ServiceRoot; no vendor Web-UI | Pass | 7m37s |
| megarac-hpe | ICMP and retained IPMI; Redfish/Web-UI unavailable; vendor SSH absent | Pass | 8m07s total; fourth attempt succeeded after three rerolls |

## Remaining limits

- **Host support:** the packaged 0.1.1 runtime is x86_64 Linux only.
- **Advantech:** external networking remains unresolved; its old NC-SI behavior is the leading explanation, and the separate QEMU 10 artifact still needs a controlled QEMU 11 retirement test.
- **iDRAC10:** SSH and IPMI work, but the Redfish result is static and the vendor Web-UI is absent.
- **MegaRAC-HPE:** service stability remains incomplete and SSH is absent.
- **Runtime identity:** runs now require matching PID and process-start evidence; an externally discovered process is reported unmanaged.
- **Rebuild closure:** executables are exact and packaged, but Debian apt dependencies are not preserved as a byte-for-byte offline source-build closure.
- **Compatibility-source closure:** iDRAC10's tracked `fake-journal` and `prebind-v2` are binaries without source here. X14 documentation describes a committed DTS and patched init source that are not present; only the hash-pinned built artifacts are tracked.
- **Physical fidelity:** a declared pass does not prove sensors, power control, host interfaces, or every peripheral match real hardware.
- **Performance:** cold-start timing remains host-load-sensitive under TCG.

## Rules moving forward

1.  1\. Preserve the run.

    Keep exact commands, console output, manifests, packets, and observation time before changing the system.

2.  2\. Test boundaries separately.

    Boot, reachability, authentication, and command behavior are different facts.

3.  3\. Compare before patching.

    Diff the last working artifact and the failing candidate before assigning a firmware cause.

4.  4\. Keep evidence strength visible.

    Do not promote a reported, historical, or inferred explanation to verified fact.

5.  5\. Add variants reluctantly.

    A new QEMU artifact needs an architecture, machine, patch-isolation, or migration requirement.

6.  6\. Define retirement tests.

    Every compatibility pin or workaround needs evidence that can eventually remove it.

7.  7\. Keep operator state truthful.

    Current health, startup history, configured capabilities, and console access must remain distinct.

8.  8\. Checkpoint completed work.

    Commit verified logical units so parallel investigation cannot strand or obscure working changes.

9.  9\. Label every substitute.

    Record what remained vendor code, what environment was reconstructed, what behavior was interposed, and which claims the substitute cannot support.

## Where the detail lives

- [Why zbmc Ships Multiple QEMU Builds](why-multiple-qemu-builds.md): exact artifact, patch, version-pin, and consolidation rationale.
- [The BMC Zoo: Engineering Lessons](zoo-lessons.md): per-SoC boot, storage, network, snapshot, and historical userland findings; the fleet table above controls current acceptance.
- [From Firmware to Bare Metal](from-firmware-to-bare-metal.md): one Advantech image from extraction through the NC-SI wall.
- [Why Dell Is Hard](why-dell-is-hard.md): iDRAC boot chains, networking, snapshots, and management-service dependencies.
- [Status regression test](../tests/status-output.sh): operator states, fleet serialization, and evidence-path behavior.
- [QEMU validation test](../tests/qemu-build-validation.sh): manifest, machine, QMP, and fleet acceptance contracts.

Last reconciled against the packaged x86_64 Linux runtime and fleet evidence on 2026-08-27.
