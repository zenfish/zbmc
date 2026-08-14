# megarac-asmb787-lab

Unpack an AMI **MegaRAC SP-X** BMC firmware image and boot it under **QEMU** as a virtual BMC — worked
end to end on the Advantech **ASMB-787** (MegaRAC SP-X 4.0, ASPEED **AST2600**). Tools, the exact boot
recipe, the firmware, and a full write-up of every wall we hit.

For OOB/BMC security research: exercise the IPMI stack, Redfish, and the web UI without owning the board.

## What works

- Firmware → bootable artifacts in ~35s (`box/build.sh`).
- Full MegaRAC userland under `qemu-system-arm -M ast2600-evb`: IPMIMain stable, redis, lighttpd,
  Redfish, event/task services.
- **Root console**: login `sysadmin` / `superuser` (uid 0).

## What doesn't (yet)

External SSH/Redfish/IPMI over host ports. The firmware's older AMI kernel (5.4.11) has a customised
NC-SI ftgmac driver that won't complete link-up against QEMU's built-in NC-SI responder. Fully
diagnosed — see the write-up. Box ships **console-accessible** (same as its sibling Cray box).

## Quickstart

```bash
# deps (macOS): brew install qemu squashfs-tools u-boot-tools dtc && pipx install jefferson
./box/build.sh                              # firmware -> work/{kernel.Image,dtb-a1.dtb,rootfs.sqfs,mtdflash.bin}
WD=./work BG=1 ./box/boot-asmb787-svc.sh    # boot, backgrounded
tail -f ./work/svc.log                      # ~2 min to 'login:'  ->  sysadmin / superuser
```

Or wire it into the `vbmc` "zoo" dispatcher (`tools/vbmc`) and use `vbmc asmb787 start|console|status`.

## Layout

```
docs/from-firmware-to-bare-metal.md   the field report: format, unpacking, boot, and every wall
skill/megarac-virtualize/SKILL.md     an agent skill (Claude/AI) that reproduces this on any MegaRAC image
tools/unpack-ami                      one-command AMI MegaRAC unpacker (FMH + SquashFS + JFFS2 + FIT)
tools/vbmc                            the zoo dispatcher (start/stop/console/status per box)
box/build.sh                          regenerate artifacts from the firmware
box/boot-asmb787-svc.sh               the exact QEMU invocation (mtdparts, ttyS4, hostfwd)
box/qemu-patch-rootfs.sh              the two IPMIMain fixes (/conf/BMC symlink + IPMI.conf trim)
box/vbmc.box                          box descriptor (creds, ports, verbs)
box/ncsi-sniff.py                     diagnostic: prove QEMU handles NC-SI internally (sees 0 frames)
firmware/…ima_enc                     the source of truth (Advantech ASMB-787, 2022-09-12)
```

## The short version of the hard parts

1. **"Encrypted" is a filename.** The `.ima_enc` is plain XZ-SquashFS + JFFS2 behind an AMI FMH table.
   Entropy ~8.0 = compressed *or* encrypted; only magic bytes tell them apart.
2. **binwalk silently skips SquashFS** on a stale sig DB — scan `hsqs`/`0x1985`/`d00dfeed`/`$MODULE$`
   yourself. `jefferson` mis-detects JFFS2 endianness on a whole image — isolate the region first.
3. **IPMIMain SIGSEGVs** without the `/conf/BMC → BMC1/<platform>` symlink and an `IPMI.conf` trimmed to
   the interfaces QEMU actually models. Both fixes in `box/qemu-patch-rootfs.sh`.
4. **Boot exactness**: flash truncated to *precisely* 64 MiB, console on `ttyS4`, `maxcpus=1`, and
   `mtdparts` ordered to match the firmware's `/etc/dupfstab` (mounts by mtdblock number).
5. **The network wall is the guest kernel, not the emulator** — QEMU already answers NC-SI; the AMI
   5.4.11 driver rejects it. Diagnose frame-traversal (`ping` the gateway) before touching the DTB.

Full detail, exact bytes, and the wrong turns: **[docs/from-firmware-to-bare-metal.md](docs/from-firmware-to-bare-metal.md)**.

## Firmware

`firmware/encrypted_ASMB-787_20220912.ima_enc` is Advantech's publicly-distributed BMC firmware,
included so this is a one-stop reproducible reference. It is redistributed for interoperability and
security-research purposes; all trademarks and copyright belong to Advantech / AMI. If the vendor
objects, open an issue and it will be removed.

## License

Scripts and docs: MIT (`LICENSE`). The firmware image is the vendor's and is not covered by that license.

Use only on hardware/firmware you're authorized to test.
