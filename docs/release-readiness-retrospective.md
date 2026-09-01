<!-- html2md:auto source=docs/release-readiness-retrospective.html source-sha256=8c24d447e5ffd433ae9320d714c19f2034611dc38fba2f8af766ae2f40b34fb1 body-sha256=2455cce5d4325d631276b05f21e52c1ceaa10018afdb97d0be5dd13b0c4b4350 -->

Repository audit · 2026-08-27

# zbmc release-readiness retrospective

A critical review of the dispatcher, eight box contracts, QEMU package, security boundaries, tests, and documentation after the fleet redesign.

## Verdict

The redesign produced a usable research fleet, but the first release candidate had contract drift: descriptors, status, startup, historical notes, and build recipes did not always agree. The audit corrected the shared control paths and narrowed acceptance to behavior demonstrated by each box. This remains isolated-lab software, not a secure multi-user service.

## What changed in the redesign

### One dispatcher

A descriptor registry, common lifecycle, exact QEMU validation, functional probes, evidence capture, console logs, and operator-focused status replaced independent session scripts.

### Exact runtime

Three x86_64 Linux QEMU executables are hash-pinned in one Docker package. Docker gives artifact consistency, not containment.

### Evidence first

Each run records its manifest, events, probes, console, captures, startup result, and termination independently.

### Explicit acceptance

A box reaches READY only when the services declared by its descriptor pass. Redfish, vendor Web-UI, console, and NC-SI are separate capabilities.

## Audit corrections

| Area | Correction |
|----|----|
| Process ownership | Fresh checkouts no longer adopt old QEMU processes. PID plus process-start identity gates reuse and stop. |
| Shutdown | Operator stops remain STOPPED instead of racing the health watcher into CRASHED. |
| Validation | Candidate-QEMU testing refuses running boxes and verifies the path and hash written to run evidence. |
| Readiness | The runtime no longer appends Web-UI or NC-SI behind the descriptor's back. ICMP startup and status policy agree. |
| Builds | Unknown boxes and failed builds return nonzero; both `build` and `start --build` run the tracked turnkey recipe. |
| Probe concurrency | Root watchers and unprivileged status commands share host-wide SSH/IPMI locks, preventing self-inflicted probe failures. |
| Networking | Direct-LAN setup rolls back partial mutation and deletes only TAPs it created. |
| Local control | QMP/GDB sockets are no longer world-writable; X10 GDB is opt-in; Docker no longer uses privileged or host-PID mode. |
| Credentials | iDRAC10 generates a per-installation SSH key. MegaRAC's injected blank-password network shells are opt-in. |
| Mutable bases | X14 NOR and eMMC bases use QEMU snapshot writes, preserving downloaded artifacts. |
| Documentation | Current operator contracts are separated from dated investigation records and mirror-only provenance is stated plainly. |

## What worked, and what did not

**Worked:** exact QEMU pins, descriptor-driven launch, permanent serial capture, functional protocol probes, cold boot as the default, immutable base images, and supplying missing board environment while retaining vendor components.

**Did not work:** treating every HTTP response as equivalent, silently calling discovered capabilities required, assuming snapshots were portable, adopting a process from a loose command-line match, trusting artifact presence as rebuild validity, and letting historical successes read as current guarantees.

The important distinction is not “real versus fake.” It is whether the vendor component was preserved and supplied its missing environment, or the component itself was replaced. Those results prove different things.

## Current acceptance boundary

| Box | Accepted | Reference cold time | Boundary |
|----|----|----|----|
| openbmc | ICMP, SSH, IPMI, Redfish, Web-UI | 4m32s | Clean control |
| nvidia-obmc | ICMP, SSH, IPMI, Redfish, Web-UI | 5m21s | OpenBMC with firmware MAC adaptation |
| supermicro-x10 | SSH, IPMI, Redfish, Web-UI | 2m38s user-net | Research license interposition |
| supermicro-x14 | ICMP, SSH, IPMI, Redfish, Web-UI | 3m31s | Scripted service environment |
| idrac9 | ICMP, SSH, IPMI, vendor Web-UI | 10m31s | Cold-only P4 boot; Redfish unavailable |
| idrac10 | ICMP, SSH, retained IPMI, static Redfish | 7m37s | No vendor Web-UI; static HTTP substitute |
| megarac-hpe | ICMP, retained IPMI | 8m07s total; fourth attempt succeeded after three rerolls | Nondeterministic cold boot; injected network shells disabled |
| advantech-asmb787 | Serial console | 9m38s | External NC-SI path unmodeled |

## Remaining release risks

- Several proprietary and derived artifacts are mirror-only; hashes establish identity, not redistribution authority. Reachable Git history still contains the former 67,109,128-byte Advantech firmware blob.
- iDRAC9 still uses a deliberately shared research login key paired with its prebuilt image.
- Snapshot bundles require a documented scrub/rebuild process before they can be treated as identity-neutral.
- Some historical helper binaries lack complete source/build provenance.
- Run manifests identify the selected QEMU exactly but do not yet enumerate every boot artifact consumed by every box.
- Live boot verification remains host- and load-sensitive; shell contract tests cannot replace a fleet run.

Current operational guidance: [Getting Started](../GETTING-STARTED.md) · threat boundary: [Security Policy](../SECURITY.md) · runtime truth: `./tools/zbmc <box> status -v`.
