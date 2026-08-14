---
name: virtualize-bmc
description: Use when booting real vendor BMC firmware (Dell iDRAC, Supermicro/HPE/NVIDIA/Advantech OpenBMC or AMI MegaRAC, etc.) under an emulator (QEMU/Renode) for reverse-engineering or security research — picks the right QEMU machine per SoC, chooses direct-kernel vs FIT vs raw-flash boot, and routes around the known walls (flash sizing, console UART, CPU bringup, the cold-boot flakiness, and the network last-mile including the AST2600 NC-SI wall). Triggers on "virtualize a BMC", "boot iDRAC/OpenBMC/MegaRAC in qemu", "emulate a BMC", "run BMC firmware without hardware".
---

# Virtualizing a vendor BMC under QEMU

Goal: boot a BMC firmware image to a shell / live IPMI / Redfish under an emulator, without the physical
server, to research the OOB management stack. This is the decision tree; the exhaustive per-box detail
(with exact flags, offsets, and error strings) is in
[docs/zoo-lessons.md](../../docs/zoo-lessons.md). For one box end-to-end (AMI MegaRAC / AST2600) see
[docs/from-firmware-to-bare-metal.md](../../docs/from-firmware-to-bare-metal.md) and the
[`megarac-virtualize`](../megarac-virtualize/SKILL.md) skill.

## Step 1 — identify the SoC → pick the QEMU machine
Read the firmware's DTB (`dumpimage`/`dtc`) or strings for the SoC. Map it:

| SoC | Vendors | QEMU |
|-----|---------|------|
| Nuvoton **NPCM750** (ARMv7) | Dell iDRAC9 | `qemu-system-arm -M npcm750-evb` |
| Nuvoton **NPCM845** (aarch64) | Dell iDRAC10 | `qemu-system-aarch64 -M npcm845-evb` |
| ASPEED **AST2600** (Cortex-A7) | Supermicro/HPE/NVIDIA/Advantech OpenBMC & MegaRAC | `qemu-system-arm -M ast2600-evb` (or a bitbaked custom machine) |
| ASPEED **AST2500** | older OpenBMC (Romulus) | `qemu-system-arm -M romulus-bmc` |
| HPE **GXP** (Cortex-A9) | HPE iLO5 (INTEGRITY RTOS, not Linux) | no QEMU machine — model in **Renode** |

## Step 2 — pick the boot method
- **Raw full-flash** (`-drive if=mtd,snapshot=on`): try this first for images that ship a bootable
  u-boot+kernel+rootfs in one blob (upstream/vendor **OpenBMC**: evb, gb200, romulus). Simplest.
- **Direct-kernel** (`-kernel/-dtb/-initrd`): required when the SPL→u-boot→OP-TEE/ROT chain can't complete
  under emulation (Dell iDRAC, Supermicro X14, MegaRAC). Carve kernel+dtb out of the **FIT** with
  `dumpimage -T flat_dt -p N` — `-kernel` **cannot unpack a FIT**. AST2600 ROT boxes: add
  `initcall_blacklist=ast2600_spitee_init,optee_driver_init` to skip the missing TrustZone model.
- Rootfs placement: MegaRAC squashfs runs as a **RAM disk** (`root=/dev/ram0 ramdisk_size=131072`);
  iDRAC/X14 rootfs is a **block dev on the sd-bus/eMMC** (`if=none`+`-device sd-card,bus=sd-bus` or
  `if=sd,index=2`).

## Step 3 — the boot-time traps (all cost hours if missed)
- **Flash/SD sizing is exact**: MegaRAC NOR = exactly 64 MiB (`truncate -s 67108864`); iDRAC SD must be
  **power-of-2** (pad to 256 MiB); X14 rootfs GPT partition number must equal its `index`.
- **Console UART**: NPCM = `ttyS0` (first `-serial`; **avoid `-nographic`**, use `-display none`);
  AST2600 = **`ttyS4`** (and **never** prepend `-serial null` — it eats the console).
- **CPU**: AST2600-evb wants 2 CPUs but CPU1 faults under TCG → **`maxcpus=1`** on the kernel cmdline.
- **`CONFIG_CMDLINE_FORCE`**: Dell kernels ignore `-append` — your lever is `init=` in an initramfs you
  own, or binary-patching the compiled-in bootargs.
- **MegaRAC IPMIMain SIGSEGV**: create `/conf/BMC → BMC1/<platform>` symlink + disable absent-hw IPMI
  interfaces in `IPMI.conf` (SMM/SOL/serial/SMBUS/BT/IPMB) + `NM_IPMB_BUS=0xFF`. See the megarac skill.
- **OpenBMC bmcweb exits 255**: `mkdir -p /var/volatile/log/redfish` first; run it via
  `systemd-socket-activate -l 0.0.0.0:443`.

## Step 4 — the network last-mile (per SoC)
- **NPCM**: on-chip GMAC (iDRAC10) works and migrates; iDRAC9's GMAC/EMC link-up NULL-crashes → fall back
  to **`-device usb-net,bus=usb-bus.0`** (works, but does NOT survive `-incoming` restore).
- **AST2600 NC-SI wall**: QEMU's ftgmac model answers NC-SI **internally** (no external responder is
  possible). Whether the link comes up is the **guest kernel version** — newer AMI/OpenBMC kernels
  negotiate fine; some older AMI kernels (~5.4.11) force NC-SI and reject QEMU's response
  (`NCSI: Handler for packet type 0x82 returned -19`) → dead eth0, console-only. **Diagnose
  frame-traversal (`ping` the gateway) before editing the DTB.** usb-net is not a fallback here (EHCI
  high-speed vs full-speed usb-net → hang).
- **OpenBMC**: disable NC-SI sideband NICs in a `-noncsi.dtb` + mask `bmc-shared-lan-discovery.service`.
- **IPMI**: usually **cipher-17 only** (`-C 17`); auth via the **factory IPMIKey** (`-K`, first 20 bytes)
  not a password on Dell/NVIDIA; give RMCP+ a long timeout (`IPMI_T≥20`) — emulated RAKP is slow.

## Step 5 — make it reliable: warm snapshots
Cold boot is nondeterministic under single-vCPU TCG (init/dbus/IPMIMain races). Once you get a good box:
QMP `stop` + `migrate exec:gzip` → `state.gz`, restore with `-incoming` over a **frozen qcow2 overlay**
(NOT `snapshot=on`, or disk/RAM diverge). Verify a live interface post-restore and re-restore if a
migrated UDP socket came back silent. Snapshot in the *service-daemon* mode you want to keep.

## Red flags (stop and rethink)
- "binwalk found nothing" → you skipped SquashFS; scan magics yourself (`hsqs`/`0x1985`/`d00dfeed`).
- eth0 "up" but nothing reachable → NC-SI/kernel wall or usb-net-didn't-migrate; don't chase iptables.
- About to write an NC-SI responder → QEMU already has one; the variable is the guest kernel.
- IPMIMain crash-loops → missing `/conf/BMC` symlink or hw-less IPMI interfaces left enabled.
- A live box "looks dead" → RMCP+ timeout too short (`IPMI_T`), or you cold-booted instead of restoring.
- Daemons dying across repeated runs → suspect your own stale pidfiles/sockets first.
