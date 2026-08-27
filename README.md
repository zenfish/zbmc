# zbmc-lab — a zoo of virtual BMCs under QEMU

Boot real vendor **BMC** (Baseboard Management Controller) firmware under QEMU, driven by one dispatcher
(`zbmc`), for reverse-engineering and security research on the out-of-band management stack (IPMI /
RMCP+, Redfish, the web UI, the RAKP auth path) **without owning the physical server**.

This is my own working "zoo" plus the tools, per-box boot recipes, a full field write-up, and an agent
skill so others can reproduce it on their own images. C&C very welcome, as are new recipies/methods/improvements
on what I have here. This turned out to be a bit more black magic than I'd anticipated beating these into
submission (at least... mostly beaten... still a bit to do.)

> **New here? → [GETTING-STARTED.md](GETTING-STARTED.md)** — clone → `./build.sh` → `zbmc openbmc start`.

> **Supported host:** zbmc v1 runs only on **x86_64 Linux** (Intel or AMD). The pinned QEMU
> executables, paths, and SHA-256 values were produced for x86_64 Linux. ARM64 hosts such as
> Raspberry Pi and Apple Silicon, macOS, and other operating systems are not currently supported.
> `build.sh` downloads and SHA-256-verifies the pinned 394 MiB QEMU Docker runtime, then installs
> a pinned `zipmi` environment. Docker keeps the exact QEMU binaries identical across Linux releases.

Resource sizing is guidance, not an enforced check. Individual BMCs request 128 MiB to 1 GiB of
guest RAM; allow roughly 2 GiB host RAM and 5 GiB free disk for one-at-a-time use. Fleet timings in
this README came from a four-core host and will be slower on smaller systems.

> It aggregates vendor firmware and documents fleet-shared *default* credentials
> that ship inside publicly-downloadable firmware (calvin, factory IPMIKeys, CredVault keys, etc.). Those
> aren't repo secrets — they're already on the internet inside the vendors' own DUP/HPM downloads; the
> value here is *documenting the danger*. Still, no live/customer secrets, no private keys, and no
> extracted rootfs trees are here (they're rather large and regenerate from firmware anyway).

## The animals

`zbmc list` shows these; run any with `zbmc <name> start`. Firmware isn't committed - `build.sh`
fetches it via `firmware/download-fw.sh` (**vendor download first, git.trouble.org mirror as fallback**,
all SHA-256-verified). The table records exact-build acceptance measured on the four-core Debby host;
it is a reproducibility baseline, not a promise that every vendor service is complete.

| `zbmc` name | Accepted function | Exact-build result / measured cold start |
|-------------|-------------------|------------------------------------------|
| **openbmc** | ICMP, SSH, IPMI, Redfish, Web-UI | pass - 5m01s |
| **nvidia-obmc** | ICMP, SSH, IPMI, Redfish, Web-UI | pass - 4m50s |
| **advantech-asmb787** | retained serial login; external network remains WIP | pass - 11m50s |
| **idrac10** | ICMP, SSH, IPMI, static Redfish ServiceRoot; no vendor Web-UI | partial - about 6m15s to the last working service |
| **megarac-hpe** | IPMI; Redfish/Web-UI observed but unstable; SSH absent | partial - no reliable READY time |
| **supermicro-x14** | ICMP, SSH, IPMI, Web-UI; Redfish not configured | pass - 4m20s |
| **supermicro-x10** | SSH, IPMI, Redfish, Web-UI plus 60s stable hold; ICMP in direct-LAN mode | pass - 2m38s user-net / 3m40s direct-LAN |
| **idrac9** | ICMP, SSH, IPMI, Web-UI; Redfish not configured in the P4 boot | pass - 12m48s |

These times were measured with one BMC at a time on a Lenovo m715q (a small four-core Intel system). 
`zbmc` learns timing profiles from completed runs, but cold firmware startup remains load-sensitive. 
Warm snapshots are explicit with `zbmc <name> start --warm` because QEMU machine-version drift can 
invalidate a checkpoint.

Supermicro X10 defaults to QEMU user networking so it works on cloud and other hosts that cannot
bridge an additional guest MAC onto the physical LAN. Its forwarded SSH and HTTPS ports are shown by
`zbmc supermicro-x10 status -v`. Set `X10_NET_MODE=direct` in `zbmc.conf` only when the selected X10
address is routable on the host LAN; direct mode adds ICMP and TAP packet capture.

Full per-box boot method, network trick, and gotchas: [docs/zoo-lessons.md](docs/zoo-lessons.md).

## Quickstart

Full walkthrough (with a glossary): **[GETTING-STARTED.md](GETTING-STARTED.md)**. The short version:

```bash
# Debian 13 on x86_64
sudo apt install docker.io squashfs-tools u-boot-tools device-tree-compiler curl git sshpass socat net-tools python3-pexpect python3-venv pipx
pipx install jefferson
export PATH="$HOME/.local/bin:$PWD/tools:$PATH"
./build.sh                     # install exact QEMU/zipmi + build every ready box
zbmc openbmc start             # boot vanilla OpenBMC (about 5 min on the reference host)
zbmc openbmc ssh 'uname -a'    # root / 0penBmc — a real shell
zbmc openbmc ipmi mc info      # RMCP+ (cipher 17)
zbmc openbmc web               # Redfish ServiceRoot
```

No firmware is committed — `build.sh` fetches what a box needs via `firmware/download-fw.sh`:

```bash
./firmware/download-fw.sh            # all, or: ./firmware/download-fw.sh openbmc
```

Each image is tried at the **vendor's public download first** (iDRAC9 pulls direct + checksum-verifies
from `dl.dell.com`), then falls back to the **project mirror at git.trouble.org**, and is **SHA-256
verified** either way. The reference (non-turnkey) boxes under `boxes/<name>/` also ship their
boot/restore/snapshot recipes + findings docs.

## Exact QEMU builds and Docker package

Every box descriptor pins a QEMU executable, version, machine, and SHA-256. `zbmc` validates all four
before launch and refuses a changed or incompatible binary. These pins are host-architecture-specific:
the current v1 build/package path supports **x86_64 Linux only** and ships two patched QEMU 11
artifacts plus Debian's exact QEMU 10.0.11 package in one pinned Docker image. Normal users receive
and verify this package automatically through `build.sh`; these commands reproduce it:

```bash
tools/build-qemu --plan qemu-11-arm
tools/build-qemu qemu-11-arm
tools/build-qemu qemu-11-idrac10

tools/package-qemu-docker /absolute/path/zbmc-qemu.docker.tar \
  /absolute/path/debian-13-qemu-10.0.11.json \
  /absolute/path/qemu-11-arm-manifest.json \
  /absolute/path/qemu-11-idrac10-manifest.json

docker load -i /absolute/path/zbmc-qemu.docker.tar
tools/validate-qemu-build --deadline 1200 /absolute/path/qemu-manifest.json box-name
```

The Docker base image and package version are pinned, and the packager verifies executable/data hashes
and QMP startup for every declared machine before export. Debian apt dependencies still resolve from the
live repository, so this is exact-artifact packaging rather than a byte-for-byte offline source rebuild.

## Network configuration

By default, each box binds to a Linux loopback alias in the **10.0.{6,7,8,9}.x** range,
broken out by vendor family:

| Subnet | Vendor | Boxes |
|--------|--------|-------|
| 10.0.6.x | AMI MegaRAC | megarac-hpe (.66) |
| 10.0.7.x | OpenBMC | openbmc (.10), nvidia-obmc (.20) |
| 10.0.8.x | Supermicro | supermicro-x10 (.10), supermicro-x14 (.14) |
| 10.0.9.x | Dell iDRAC | idrac9 (.9), idrac10 (.10) |
| configured pool `.50` | Advantech | advantech-asmb787 |

If your network already uses the default 10.0.{6,7,8,9}.x range, copy `zbmc.conf.example`
to `zbmc.conf` (gitignored) and set **one** of:

```bash
# Pool mode — relocate every box into any /24 you control (first 3 octets):
ZBMC_POOL=10.250.0       # still in 10/8 but out of the way
# ZBMC_POOL=192.168.9    # or a completely different block
# → openbmc=.10, nvidia-obmc=.11, x10=.20, x14=.21,
#   idrac9=.30, idrac10=.31, megarac-hpe=.40, asmb787=.50

# Per-box override — when you only have a few free IPs:
ZBMC_IP_idrac9=172.16.0.99
ZBMC_IP_openbmc=192.168.1.100
```

Priority: per-box `ZBMC_IP_<name>` > pool > built-in default.
Full allocation table and examples: **[zbmc.conf.example](zbmc.conf.example)**.

## Layout

```
build.sh      build every ready box's boot artifacts into work/<box>/  (./build.sh --list to preview)
tools/        unpack-ami (MegaRAC), unpack-idrac (Dell DUP/FIT), zbmc (the dispatcher)
boxes/<name>/ per-box zbmc.box + boot/build/restore/snapshot scripts + findings docs
docs/         from-firmware-to-bare-metal.md (advantech-asmb787 deep-dive) · zoo-lessons.md (cross-box)
skill/        megarac-virtualize/ + virtualize-bmc/ — agent skills reproducing this on new firmware
firmware/     download-fw.sh — fetches all firmware (vendor first, git.trouble.org mirror fallback)
```

## What you'll learn from the docs

- **[docs/from-firmware-to-bare-metal.md](docs/from-firmware-to-bare-metal.md)** — one box end to end:
  the "encrypted" misnomer, AMI FMH / SquashFS / JFFS2 / FIT unpacking (and the binwalk & jefferson
  traps), the exact QEMU flags and why, the IPMIMain SIGSEGV fixes, and the NC-SI networking wall in full.
- **[docs/zoo-lessons.md](docs/zoo-lessons.md)** — the cross-box patterns: QEMU machine per SoC,
  direct-kernel vs FIT vs raw-flash boot, flash sizing traps, cold-boot-flaky → warm-snapshot (QMP
  migrate), the network last-mile per SoC (usb-net on NPCM vs the AST2600 NC-SI wall), and the OpenBMC /
  MegaRAC / iDRAC userland fixes.

## License / use

Scripts + docs: MIT (`LICENSE`). Firmware images are the respective vendors' and are not covered by it.
Use only on hardware/firmware you're authorized to test.
