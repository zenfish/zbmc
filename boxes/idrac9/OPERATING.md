<!-- html2md:auto source=boxes/idrac9/OPERATING.html source-sha256=2be8cba0370ad896abb77e358227a7de3255b3e3c3ef99787509353e770febfa body-sha256=d3e87e95152497397428124f21302a944603f5391af0a6613e1a28738e3e10ea -->

**Historical operating record.** This Apple Silicon/manual phase guide predates the supported x86_64 Linux dispatcher. Current iDRAC9 is cold-only with accepted ICMP, SSH, IPMI, and vendor Web-UI; Redfish is unavailable. Use the repository README and `./tools/zbmc idrac9 status -v`.

# Virtual iDRAC9 — operating guide

*How to run the virtual iDRAC9, what the boot looks like (and how long), how to change its network identity, and how to tell when it's actually up. Companion to the [design writeup](index.md). Phase-4 (`mini.target`) is the working build.*

## 0 · Where it runs

It runs **on this Mac** (Apple-silicon, `qemu-system-arm`) — **not** on the dell. The dell T710 is the real iDRAC6 box (`192.168.0.22/.23`) and is untouched. The virtual iDRAC9 is pure QEMU emulation of Dell's own ARM firmware on the `npcm750-evb` machine; it can be moved to any host with `qemu-system-arm`. The guest is NAT'd behind QEMU user-net — reachable only via the host-forwarded `127.0.0.1` ports below, not on the LAN.

## 1 · Run it

    cd ~/phd/bmc/dell/idrac9-virtual
    ./build-p4.sh        # repack initramfs (init.p4.custom) + ship synthesized cfgdb defaults
    ./run-p4.sh          # boot under QEMU; serial console to stdout (Ctrl-A X to quit)
    ./ready.sh           # (separate terminal) poll the console log, report boot stage / readiness

Headless / background pattern (what the dev loop uses): `nohup ./run-p4.sh > /tmp/p4.log 2&1 &`, then watch `/tmp/p4.log` with `./ready.sh /tmp/p4.log`.

## 2 · Boot timeline (measured, under emulation)

Emulation is ~0.4× real-time and the mesh comes up *slowly*; the populated cfgdb roughly doubles mesh time vs. an empty one. Representative wall-clock from a console log:

| t (≈) | Stage | Marker in the serial log |
|----|----|----|
| 0 s | initramfs `/init` runs; mounts rootfs, fakes persistence, injects cfgdb | `######## VIRTUAL iDRAC9 Phase-4 ########` |
| ~55 s | kernel done, switch_root → systemd `mini.target` | `Startup finished … (kernel)` |
| ~60–90 s | dbus + `dfserver`/`aim`/`cfgmgr` up; **racadm functional** | cfgmgr `active`; `Object value modified successfully` |
| ~100–130 s | `dsm-sa-datamgr` active → **SMIL pipes** open (instrumentation live) | `/run/dm/.ipc/dcsmilpipea` exists; `dcsmilpipe wait: …present=yes` |
| ~3–4 min | eventmgr + populators settled; full instrumentation | 5 `dsm-sa-pop@*` units active |

**Caveats.** (1) `multi-user.target` never settles — 182 hardware-less services thrash (dead end); the working build is the custom `mini.target` + a script that starts only the mesh. (2) The `~7 min` "Startup finished" figure systemd prints is inflated by the diagnostic service's deliberate waits, not real boot time. (3) Networking uses a USB-net gadget (`usb-nic-nvgpu`); the on-chip GMAC/EMC crash the kernel on link-up.

## 3 · Network identity — the IP/port knobs

Four layers, each independently settable:

| Layer | Edit here | Default |
|----|----|----|
| QEMU slirp subnet | `run-p4.sh` — `-netdev user,…` (add `net=`/`host=`/`dhcpstart=`) | `10.0.2.0/24`, gw `.2`, guest `.15` |
| Guest kernel NIC IP | `init.p4.custom` (dbg.sh): `ip addr add 10.0.2.15/24 dev $NIC` | `10.0.2.15` |
| Host → guest ports | `run-p4.sh`: `hostfwd=tcp::2222-:22,udp::6623-:623` | ssh `2222`, IPMI `6623` |
| iDRAC config IP (cfgdb) | `scripts/build-cfgdb-defaults.py` → `_IP` (rebuild after) | `10.0.2.15` |

To lock to an arbitrary address: set `_IP` (+ the matching slirp subnet and the kernel `ip addr`), then `./build-p4.sh`. **Known limit:** the iDRAC's *operational* address (`CurrentIPv4`, what the IPMI/RMCP listener binds to) is read-only and derived by osinterface from the static config — and that derivation isn't firing on the faked NIC yet (it stays `0.0.0.0`). So the *static/config* IP is fully settable; the *operational* one is the open blocker for udp/623 — see §5 and the [design doc](index.md#s7).

## 4 · How to tell it's up

There is no single "ready" signal yet; readiness is observed from the serial console. `ready.sh` greps the log and reports the highest stage reached:

    ./ready.sh /tmp/p4.log
    # STAGE 5/6  racadm: UP   dbus: up   mesh: up   SMIL: up   udp623: DOWN

Manual checks (what `ready.sh` automates), in order of "more up":

- **booted** — log has `VIRTUAL iDRAC9 Phase-4` then `switch_root`.
- **dbus** — `dbus-broker.service` active.
- **racadm** — `racadm get iDRAC.IPv4.Address` returns a value (cfgmgr up).
- **instrumentation** — `/run/dm/.ipc/dcsmilpipea` socket exists (datamgr's SMIL).
- **IPMI/RAKP** — udp/623 in `/proc/net/udp` (port `026F`) — *not yet; the §5 blocker.*

The diagnostic service (`virt-debug.service`) dumps a full state block between `==VIRTDBG==` / `==VIRTDBG-END==` markers near the end of boot.

## 5 · What works / what's open

| Capability | State |
|----|----|
| Boot Dell kernel + rootfs, SSH-able shell (Phase-3) | ✅ |
| dbus + object mesh (dfserver/aim/cfgmgr) + DSM-SA instrumentation | ✅ |
| **racadm — read & write real config** (`get/set iDRAC.*`) | ✅ |
| fullfw runs (sensors/SDR loaded, crash-free) | ✅ |
| IPMI/RAKP on udp/623 | ⚠ blocked — `CurrentIPv4=0.0.0.0` ⇒ fullfw's `RMCPCreateSocketInstance` fails. Needs osinterface to apply the static IP (or a bind-patch). |
| HTTPS / Redfish | — future |

------------------------------------------------------------------------

*Operating guide for the Phase-4 build. Design + RE detail in [index.html](index.md) (§7 = the mesh/cfgdb/RAKP teardown). Written 2026-06-24.*
