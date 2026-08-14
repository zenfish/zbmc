# vbmc-lab — a zoo of virtual BMCs under QEMU

Boot real vendor **BMC** (Baseboard Management Controller) firmware under QEMU, driven by one dispatcher
(`vbmc`), for reverse-engineering and security research on the out-of-band management stack (IPMI /
RMCP+, Redfish, the web UI, the RAKP auth path) **without owning the physical server**.

This is the working "zoo" plus the tools, per-box boot recipes, a full field write-up, and an agent
skill so others can reproduce it on their own images.

> **New here? → [GETTING-STARTED.md](GETTING-STARTED.md)** — clone → build → run the `asmb787` box in
> three commands.

> **Private on purpose.** It aggregates vendor firmware and documents fleet-shared *default* credentials
> that ship inside publicly-downloadable firmware (calvin, factory IPMIKeys, CredVault keys, etc.). Those
> aren't repo secrets — they're already on the internet inside the vendors' own DUP/HPM downloads; the
> value here is *documenting the danger*. Still, no live/customer secrets, no private keys, and **no
> extracted rootfs trees** are committed (they're huge and regenerable from firmware anyway).

## The animals

| Box | Vendor / stack | SoC → QEMU machine | Access that works | Console / creds |
|-----|----------------|--------------------|-------------------|------------------|
| **asmb787** | Advantech · AMI MegaRAC SP-X 4.0 | AST2600 → `ast2600-evb` | console (full stack) | ttyS4 · `sysadmin`/`superuser` · *ext net blocked, see writeup* |
| **cray** | HPE Cray XD670 · MegaRAC SP-X | AST2600 → `ast2600-evb` | IPMI 2.0 RMCP+ ✓ · authed Redfish ✓ | ttyS4 · IPMI `admin`/`superuser`, console `sysadmin`/`superuser` |
| **x14** | Supermicro · OpenBMC | AST2600 → `ast2600-evb` | ssh ✓ · remote Redfish ✓ · IPMI ◑ | socket · `ADMIN`/`ADMIN` (uid 10000+sudo), root `0penBmc` |
| **idrac9** | Dell · iDRAC9 | NPCM750 → `npcm750-evb` | ssh root ✓ · IPMI RMCP+ ✓ · Redfish (local) ✓ | ttyS1 · root key + factory IPMIKey; racadm not ipmitool |
| **idrac10** | Dell · iDRAC10 | NPCM845 → `npcm845-evb` | IPMI RMCP+ ✓ (`IPMI_T≥25`) · console (cold) ✓ | socat serial · factory IPMIKey (`-K`) |
| **gb200** | NVIDIA GB200NVL · OpenBMC | AST2600 → `gb200nvl-bmc` | OEM IPMI (NetFn 0x3C) — BIOS-pwd leak | — |
| **evb-openbmc** | vanilla OpenBMC (baseline) | AST2600 → `ast2600-evb` | ssh + Redfish + IPMI-LAN ✓ | Mfr 0 baseline for diffing OEM builds |

Live-measured; some interfaces are partial (◑) under emulation. Full per-box detail:
[docs/zoo-lessons.md](docs/zoo-lessons.md).

## Quickstart (asmb787, the fully-included example)

```bash
# deps (macOS): brew install qemu squashfs-tools u-boot-tools dtc && pipx install jefferson
./boxes/asmb787/build.sh                       # firmware -> kernel/dtb/rootfs/mtdflash  (~35s)
WD=./work BG=1 ./boxes/asmb787/boot-asmb787-svc.sh
tail -f ./work/svc.log                          # ~2 min -> login: sysadmin / superuser (uid 0)
```

Other boxes ship their **boot/build/restore/snapshot recipes** + findings docs under `boxes/<name>/`.
The big/proprietary firmware (iDRAC DUPs, x14 128 MB image) exceeds GitHub's 100 MB/file limit, so it's
**fetched from the vendors** rather than committed:

```bash
./firmware/download-fw.sh            # all, or: ./firmware/download-fw.sh idrac9
```

iDRAC9 pulls directly + checksum-verifies from `dl.dell.com`; iDRAC10 / x14 are JS/EULA-gated so the
script prints the exact vendor page, filename, and expected SHA-256 to drop in and verify. All of it is
firmware the vendors distribute publicly and anonymously — the script just automates it and pins hashes.

## Layout

```
tools/        unpack-ami (MegaRAC), unpack-idrac (Dell DUP/FIT), vbmc (the dispatcher)
boxes/<name>/ per-box vbmc.box + boot/build/restore/snapshot scripts + findings docs
docs/         from-firmware-to-bare-metal.md (asmb787 deep-dive) · zoo-lessons.md (cross-box patterns)
skill/        megarac-virtualize/ + virtualize-bmc/ — agent skills reproducing this on new firmware
firmware/     asmb787 image (fits) + download-fw.sh to fetch the big Dell/Supermicro ones from the vendors
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
