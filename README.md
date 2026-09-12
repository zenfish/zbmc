# zbmc-lab — a zoo of virtual BMCs under QEMU

Boot real vendor **BMC** (Baseboard Management Controller) firmware under QEMU, driven by one dispatcher
(`zbmc`), for reverse-engineering and security research on the out-of-band management stack (IPMI /
RMCP+, Redfish, the web UI, the RAKP auth path) **without owning the physical server**.

This is the working "zoo" plus the tools, per-box boot recipes, a full field write-up, and an agent
skill so others can reproduce it on their own images.

> **New here? → [GETTING-STARTED.md](GETTING-STARTED.md)** — clone → `./build.sh` → `zbmc openbmc start`.

> **Private on purpose.** It aggregates vendor firmware and documents fleet-shared *default* credentials
> that ship inside publicly-downloadable firmware (calvin, factory IPMIKeys, CredVault keys, etc.). Those
> aren't repo secrets — they're already on the internet inside the vendors' own DUP/HPM downloads; the
> value here is *documenting the danger*. Still, no live/customer secrets, no private keys, and **no
> extracted rootfs trees** are committed (they're huge and regenerable from firmware anyway).

## The animals

`zbmc list` shows these; run any with `zbmc <name> start`. **Sixteen are turnkey from a clone**; the
rest are reference recipes. Firmware isn't committed — `build.sh` fetches it via
`firmware/download-fw.sh` (**vendor download first, git.trouble.org mirror as fallback**, all
SHA-256-verified).

| `zbmc` name | Description | Turnkey? · boot |
|-------------|-------------|:----------------:|
| **openbmc** | Vanilla upstream OpenBMC (Phosphor/AST2600) — clean baseline, NO OEM (Mfr 0); ipmi-LAN + Redfish + ssh all live | ✅ turnkey (net) · ~2 min |
| **nvidia-obmc** | Nvidia GB200NVL BMC (OpenBMC/AST2600) — NVIDIA OEM IPMI 0x3C; ipmi-LAN works (cipher-17 only) + busctl | ✅ turnkey (net) · ~2 min |
| **advantech-asmb787** | Advantech ASMB-787 BMC (AMI MegaRAC SP-X 4.0 / AST2600, armv7l) — CONSOLE-green (sysadmin/superuser); ext net WIP | ✅ turnkey (console) · ~2 min |
| **idrac10** | Dell iDRAC10 (NPCM845/aarch64) — warm-snapshot restore; ssh + IPMI (zipmi -K factory key) | ✅ turnkey (snap) · ~20 s |
| **megarac-hpe** | HPE XD670 BMC (AMI MegaRAC SP-X / AST2600, armv7l) — warm-snapshot restore; IPMI 2.0 RMCP+ + authed Redfish (admin/superuser) | ✅ turnkey (snap) · ~20 s |
| **supermicro-x14** | Supermicro X14 BMC (Phosphor OpenBMC/AST2600-ROT) — warm-snapshot restore; Redfish + IPMI cipher-17 (ADMIN:ADMIN) | ✅ turnkey (snap) · ~20 s |
| **supermicro-x10** | Supermicro X10 BMC (AST2400, FW 3.93) — weak-cipher oracle (IPMI suites 0-14); ADMIN:ADMIN | ✅ turnkey (net) · ~1 min |
| **supermicro-x12** | Supermicro X12SPI BMC (ATEN/AST2600, FW 01.07.20) — jffs2-on-NOR; ADMIN:ADMIN | ✅ turnkey (net) · ~2 min |
| **supermicro-x13** | Supermicro X13 2401MS BMC (ATEN/AST2600 ROT20, FW 01.07.01) — eMMC-root; ADMIN:ADMIN | ✅ turnkey (net) · ~2 min |
| **supermicro-x13d** | Supermicro X13DAi C301MS BMC (ATEN/AST2600 ROT2HW2, FW 01.08.08) — eMMC-root; ADMIN:ADMIN | ✅ turnkey (net) · ~2 min |
| **supermicro-h13f** | Supermicro H13 F401MS BMC (ATEN/AST2600, FW 01.06.05) — jffs2-on-NOR; ADMIN:ADMIN | ✅ turnkey (net) · ~2 min |
| **supermicro-h13s** | Supermicro H13SSF E401MS BMC (ATEN/AST2600 ROT20, FW 01.09.16) — eMMC-root; ADMIN:ADMIN | ✅ turnkey (net) · ~2 min |
| **h3c-hdm** | H3C HDM3 BMC (OpenBMC phosphor + lighttpd / AST2600, FW 2.06.02) — admin:Password@_ | ✅ turnkey (net) · ~3 min |
| **fujitsu-irmc** | Fujitsu iRMC S6 BMC (AMI MegaRAC SP-X / AST2600, FW 02.63S) — admin:admin / sysadmin:superuser | ✅ turnkey (net) · ~3 min |
| **bluefield-bmc** | NVIDIA BlueField-3 DPU BMC (OpenBMC Moonraker/AST2600, BF-26.04-8) — cipher-17-only IPMI; root:0penBmc | ✅ turnkey (net) · ~3 min |
| **opengear-om2200** | Opengear OM2200 (x86-64, FW 25.11.7) — console manager, nginx+Lua; root:default; no IPMI | ✅ turnkey (net) · ~2 min |
| **lenovo-xcc2** | Lenovo XCC2 BMC (Vertiv Stingray-Z51 / AST2600, FW 1.10) — kernel boots, vendor /init hw-bound (experimental) | ✅ turnkey (console) · ~2 min |
| **idrac9** | Dell iDRAC9 (NPCM750) — Phase-4 mesh + RAKP + Redfish | recipe · — |

**Boot times** are approximate on an unloaded host — a busy machine (or a dozen stray qemus) is much slower. Two classes: **cold** boxes build/boot the firmware fresh (~2 min to services); **warm-snapshot** boxes (idrac10, supermicro-x14) resume a captured RAM state (~15–30 s).

Full per-box boot method, network trick, and gotchas: [docs/zoo-lessons.md](docs/zoo-lessons.md).

## Quickstart

Full walkthrough (with a glossary): **[GETTING-STARTED.md](GETTING-STARTED.md)**. The short version:

```bash
# deps (macOS): brew install qemu squashfs-tools u-boot-tools dtc sshpass && pipx install jefferson
export PATH="$PWD/tools:$PATH"
./build.sh                     # fetch firmware (vendor/mirror) + build every ready box
zbmc openbmc start             # boot vanilla OpenBMC (~2 min)
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

## Layout

```
build.sh      build every ready box's boot artifacts into work/<box>/  (./build.sh --list to preview)
tools/        unpack-ami (MegaRAC), unpack-idrac (Dell DUP/FIT), aten-carve/aten-emmc/aten-boot
              (Supermicro ATEN FIT/dtb patch + eMMC), zbmc (the dispatcher)
boxes/<name>/ per-box zbmc.box + boot/build/restore/snapshot scripts + findings docs
docs/         from-firmware-to-bare-metal.md (advantech-asmb787 deep-dive) · zoo-lessons.md (cross-box) ·
              firmware-sources.md (vendor landing pages + hashes)
skill/        megarac-virtualize/ + virtualize-bmc/ — agent skills reproducing this on new firmware
firmware/     download-fw.sh — fetches all firmware (vendor first, git.trouble.org mirror fallback) ·
              manifest.txt + checksum-manifest.sh — SHA-256 reference list for mirror hosting
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
