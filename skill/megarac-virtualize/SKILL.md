---
name: megarac-virtualize
description: Use when unpacking or adapting authorized AMI MegaRAC SP-X firmware for zbmc. Covers raw FMH images versus HPM.1 wrappers, safe extraction and repacking, per-firmware /conf and IPMIMain reconstruction, AST2600 NC-SI limits, injected-access labeling, and current Advantech/HPE acceptance.
---

# Virtualize AMI MegaRAC firmware

For current boxes, use the packaged x86_64 Linux runtime and descriptor:

```bash
./build.sh advantech-asmb787   # or: megarac-hpe
sudo ./tools/zbmc advantech-asmb787 start
./tools/zbmc advantech-asmb787 status -v
./tools/zbmc advantech-asmb787 console
```

Do not launch an arbitrary `qemu-system-arm`. The descriptors pin and validate the exact executable,
version, SHA-256, machine, and QMP startup. Do not expose a patched MegaRAC guest outside an isolated lab.

## Classify the input first

- Linear `.ima`, `.ima_enc`, `.img`, or raw `.bin`: use `tools/unpack-ami`. An `encrypted` filename is
  often a production-label misnomer; distinguish compression from encryption by structure and magic,
  not entropy alone.
- PICMG HPM.1 `.hpm`: it is a wrapper, not a linear NOR image. Follow
  `boxes/megarac-hpe/build-from-hpm.sh` to carve verified regions and reconstruct flash. Never truncate
  or attach the HPM itself as NOR.
- Scan for FMH `$MODULE$`, SquashFS `hsqs`, JFFS2 `85 19`, and FIT/DTB `d0 0d fe ed`. `binwalk found
  nothing` is not evidence that the filesystems are absent.

`tools/unpack-ami` writes `fw-blobs/`, extracted trees under `fw-filesystems/`, JFFS2 output under
`fw-jffs2/`, FIT material under `fw-fit/`, and `MANIFEST.txt`. Install Jefferson with `pipx`, not a
system `pip`, on PEP 668 Debian hosts.

## Reconstruct the minimum environment

1. Extract the kernel and DTB from a FIT with `dumpimage`; QEMU `-kernel` cannot unpack the FIT.
2. Determine partition numbering from the image's own mount configuration. MegaRAC often mounts by
   `mtdblockN`, so names alone are insufficient.
3. Seed `/conf` only after its backing filesystem is mounted and before its first consumer. Create the
   exact `/conf/BMC -> BMC1/<platform>` target required by that firmware.
4. Disable only hardware interfaces proven absent from the emulated machine. Advantech and HPE require
   different KCS/interface masks; there is no universal `IPMI.conf` edit.
5. Repack from a clean output with `mksquashfs ... -noappend`. Keep the original filesystem immutable.
6. Copy the canonical flash to a per-run image before launch. MegaRAC writes `/conf`; attaching the
   baseline writable destroys reproducibility.

The retained vendor component versus substitute distinction is mandatory. `/conf` seeding, interface
masking, and board-state reconstruction can preserve the vendor IPMIMain path. HPE's direct root console,
SMASH replacement, blank-password Dropbear, and unauthenticated telnet are injected operator-access
substitutions; they do not prove vendor SSH, SMASH, or authentication behavior.

## Network and acceptance

QEMU's current AST2600 FTGMAC handles NC-SI internally and does not forward NC-SI frames to the netdev.
An external responder cannot repair this path. Diagnose kernel link negotiation separately from service
startup, protocol reachability, authentication, and functional behavior.

Current measured boundaries:

- Advantech ASMB-787: retained serial login only; about 11m50s on the reference host. Vendor userland
  starts, but external SSH/IPMI/Redfish/Web-UI are not accepted because the old guest rejects QEMU's
  NC-SI response.
- HPE XD670 MegaRAC: partial. Retained vendor IPMI works; Redfish/Web-UI are unstable; SSH is absent;
  there is no reliable full-service READY time. Cold IPMIMain startup may reroll after `MsgHndlr` faults.

Console access proves local operator access, not external management functionality. Accept a service
only through its declared functional probe and preserve the run evidence and console log.

Read [From Firmware Blob to Bare Metal](../../docs/from-firmware-to-bare-metal.md) for the Advantech
field report and [Why Virtualizing BMC Firmware Was Hard](../../docs/why-bmc-virtualization-is-hard.html)
for the evidence taxonomy and current fleet limits.
