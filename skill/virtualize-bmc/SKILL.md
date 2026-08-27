---
name: virtualize-bmc
description: Use when adapting authorized BMC firmware to zbmc/QEMU or diagnosing a virtual BMC. Covers SoC and boot routing, exact-QEMU selection, service acceptance, evidence boundaries, storage safety, and current per-box limits. Triggers on "virtualize a BMC", "boot iDRAC/OpenBMC/MegaRAC in QEMU", "emulate BMC firmware", and "add a zbmc box".
---

# Virtualize BMC firmware with zbmc

Use the repository contract, not a hand-written QEMU command, for registered boxes. Current runtime
authority is `README.md`, `tools/zbmc`, the selected `boxes/<name>/zbmc.box`, and tests. The 0.1.1 package
supports x86_64 Linux only.

```bash
./build.sh <box>
sudo ./tools/zbmc <box> start
./tools/zbmc <box> status -v
./tools/zbmc <box> console
```

Each descriptor pins a QEMU executable, SHA-256, exact version, machine, and QMP smoke test. Never
substitute a PATH-selected QEMU. `-q /absolute/path/qemu-system-*` deliberately validates and persists
a replacement; use it only after proving the candidate boots that box and passes its functional probes.

## Define the claim before changing firmware

Record these separately:

1. What booted: bootloader, kernel, init, vendor services.
2. Which vendor components remain in each request path.
3. Which missing board/environment state was reconstructed.
4. Which behavior was interposed or replaced.
5. Which functional probes establish acceptance.

Supplying a missing environment to a retained vendor component supports bounded claims about that
component. Replacing the endpoint proves only integration around the substitute. A listening port,
process, login prompt, ICMP reply, or synthetic response is not proof of IPMI, Redfish, SSH, or Web-UI
functionality. Preserve console output and run evidence; use `status -v` and `evidence` to locate both.

## Route by SoC and image

Read the DTB/FIT and firmware metadata before choosing a machine.

| SoC / current box | Packaged QEMU machine |
|---|---|
| NPCM750 / iDRAC9 | QEMU 11 ARM, `npcm750-evb` |
| NPCM845 / iDRAC10 | patched QEMU 11 AArch64, `npcm845-evb` |
| AST2400 / Supermicro X10 | patched QEMU 11 ARM, `supermicrox11-bmc` |
| AST2600 / OpenBMC, X14, MegaRAC | QEMU 11 ARM, `ast2600-evb` |
| AST2600 / NVIDIA GB200 | QEMU 11 ARM, `gb200nvl-bmc` |
| AST2600 / Advantech | preserved Debian QEMU 10.0.11, `ast2600-evb` |

No current package covers HPE GXP/iLO5. Do not infer that a nearby ARM machine is compatible.

Choose the least invasive boot path that works:

- Full flash for complete OpenBMC images whose boot chain is modeled.
- Direct kernel/DTB/initramfs when SPL, ROT, OP-TEE, CPLD, or storage initialization blocks first-stage boot.
- Extract a FIT with `dumpimage`; QEMU `-kernel` does not unpack a FIT.
- MegaRAC uses a RAM-disk root. iDRAC9/10 use SD-backed filesystems. Current X14 service boot uses
  the vendor initramfs as `root=/dev/ram` while retaining eMMC at `if=sd,index=2`.
- Never attach a canonical writable flash image. Copy it to a per-run image or use the descriptor.

## Scope workarounds narrowly

- NPCM console is `ttyS0`; AST2600 console is normally `ttyS4`. Do not prepend a serial device that
  consumes the expected console.
- Dell kernels may force compiled boot arguments. Confirm `CONFIG_CMDLINE_FORCE` before relying on
  `-append`.
- X14 direct-kernel boot only uses `maxcpus=1`, the non-NC-SI DTB, service masks, and manual bmcweb
  preparation. Do not apply those changes to full-flash OpenBMC or NVIDIA boots.
- QEMU's current AST2600 FTGMAC consumes NC-SI internally. An external responder cannot repair the
  Advantech path; its older guest remains console-only pending a kernel or emulator compatibility fix.
- Never infer credentials, cipher, or timeout from vendor family. Read `IPMI_USER`, `IPMI_PW`,
  `IPMI_KEY`, `IPMI_OPTS`, and `IPMI_T` from the descriptor. Dell uses factory keys; NVIDIA uses its
  declared password plus cipher 17.

Warm migration is box-specific. Use only the descriptor's snapshot/restore behavior with its pinned
QEMU and matched storage. iDRAC9 and iDRAC10 are cold-only; X14 and MegaRAC-HPE opt into their matched
snapshots with `start --warm`. Re-run every declared functional probe after restore.

## Add or change a box

1. Preserve the source artifact and hashes; identify the exact container, partitions, SoC, DTB, UART,
   storage layout, and boot arguments.
2. Start from the closest existing descriptor and packaged QEMU. Add a QEMU variant only after a
   controlled comparison proves an architecture, machine, patch, or migration requirement.
3. Keep build artifacts under `work/<box>` and runtime writes in per-run copies.
4. Declare only intended service acceptance in `ZBMC_REQUIRED_SERVICES`; keep Redfish and Web-UI
   separate. Add a functional probe for every declared service.
5. Start with `--no-wait`, follow with `status --follow`, and inspect the recorded console log.
6. Add one focused regression test for the compatibility or lifecycle rule introduced.

Read [Why Virtualizing BMC Firmware Was Hard](../../docs/why-bmc-virtualization-is-hard.md) for the
evidence model and [Why zbmc Ships Multiple QEMU Builds](../../docs/why-multiple-qemu-builds.md) for
runtime provenance. `docs/zoo-lessons.md` preserves useful engineering history; verify every operational
claim against the current descriptor and tests before reuse.
