---
name: megarac-virtualize
description: Use when you have an AMI MegaRAC (SP-X, ASPEED AST2500/AST2600) BMC firmware image and want to unpack it and boot it under QEMU as a virtual BMC for security research — covers the "encrypted" misnomer, FMH/SquashFS/JFFS2 extraction, the IPMIMain SIGSEGV fix, mtdparts matching, and the NC-SI networking wall. Also triggers on "virtualize a BMC", "boot vendor firmware in qemu", "unpack .ima/.ima_enc/MegaRAC firmware".
---

# Virtualizing an AMI MegaRAC BMC under QEMU

You have a vendor BMC firmware image (AMI MegaRAC SP-X on an ASPEED AST2600, e.g. Advantech ASMB-xxx,
HPE Cray XD670, many Gigabyte/Supermicro boards). Goal: unpack it and boot it under QEMU `ast2600-evb`
to a console/root shell so the OOB stack (IPMI, Redfish, web UI) can be researched without hardware.

Read [`from-firmware-to-bare-metal.md`](../../docs/from-firmware-to-bare-metal.md) for the full field
report with exact bytes and dead-ends. This skill is the checklist.

## When to use
- Input is an AMI MegaRAC firmware blob (`.ima`, `.ima_enc`, `.bin`, `.hpm`, or a raw flash dump).
- You want a bootable virtual BMC, not just to read files out of the image.
- Prefer this over generic "run binwalk" — MegaRAC has specific traps binwalk silently fails on.

## Prerequisites
`qemu-system-arm` (≥8, tested on 11.0.0), `squashfs-tools` (unsquashfs/mksquashfs), `u-boot-tools`
(dumpimage), `jefferson` (pip, JFFS2), `dtc`, `python3`. The `tools/unpack-ami` script in this repo
codifies the extraction.

## Workflow

### 1. Identify — do NOT trust the extension or `file(1)`
- `.ima_enc` / "encrypted" is usually a **misnomer**. Verify: dump the first 256 bytes (ARM vectors +
  U-Boot markers like `0xdeadbeef` = plaintext) and compute a **per-MB entropy profile**. A solid
  ~8.0 bits/byte *everywhere* = maybe encrypted; ~8.0 in one region with plaintext elsewhere =
  **compressed**, not encrypted. Compression and AES look identical on entropy alone — distinguish by
  finding magic bytes inside.

### 2. Unpack — scan magics yourself, don't rely on binwalk
- **Never trust "binwalk found nothing"** — degraded signature DBs skip SquashFS. Scan for magics:
  `hsqs` (SquashFS LE), `sqsh` (BE), `0x1985` = bytes `85 19` (JFFS2), `d00dfeed` (FIT/DTB),
  `$MODULE$` (AMI FMH header, 64 KB-aligned).
- **SquashFS**: read exact size from `bytes_used` at superblock offset `0x28` (u64 LE), compressor at
  `0x14` (u16); carve and `unsquashfs`. FMH module payloads start `0x10000` after the `$MODULE$` header.
- **JFFS2**: `jefferson` auto-detects endianness **per file** and guesses **big-endian on the whole
  image → 0 nodes**. Carve the single JFFS2 region out first (it's usually LE) then run jefferson on it.
  No `--little-endian` flag exists; isolation is the fix.
- Just run `tools/unpack-ami <fw>` — it does all of the above and emits `rootfs/`, `www/`, JFFS2 trees,
  the FIT, and any signing key.

### 3. Extract the kernel + DTB from the FIT
- QEMU's `-kernel` **cannot unpack a FIT** (`d00dfeed`). Use dumpimage:
  ```
  dumpimage -l osimage.itb                          # find image indices
  dumpimage -T flat_dt -p 0 -o kernel.Image osimage.itb   # index 0 = Linux kernel
  dumpimage -T flat_dt -p 1 -o board.dtb    osimage.itb   # index 1 = the *_a1 dtb
  ```

### 4. Patch the rootfs for IPMIMain (or it SIGSEGV/reboot-loops)
Two fixes (see `box/qemu-patch-rootfs.sh`), both from Ghidra RE of IPMIMain:
- **`/conf/BMC` symlink**: IPMIMain opens literal `/conf/BMC/IPMI.conf`. Inject into
  `etc/init.d/ipmistack` (before each IPMIMain launch): seed `/conf` from `/etc/defconfig`, then
  `ln -sfn BMC1/<platform> /conf/BMC`, gated on a `/conf/AMI` sentinel.
- **Trim `IPMI.conf`** to hardware QEMU models — keep LAN/UDS/KCS; set
  `SUPPORT_SMM_IFC=0 SUPPORT_SOL_IFC=0` (and SERIAL/SMBUS/BT/IPMB=0), and `NM_IPMB_BUS=0xFF`
  (else the Node-Manager guard self-stops). Repack with `mksquashfs … -comp xz -all-root`.

### 5. Boot
- Machine `-M ast2600-evb`, console **`ttyS4`** (AST2600 = UART5), **`maxcpus=1`** (CPU1 faults).
- **Flash size must be EXACT**: QEMU's `m25p80` for `w25q512jv` wants precisely 64 MiB — `truncate -s
  67108864 mtdflash.bin` (vendor images are often a few hundred bytes over).
- **mtdparts numbering must match `/etc/dupfstab`** (MegaRAC's `mountallapp` mounts by `mtdblockN`, not
  name). If your image is a linear NOR, point partitions at real offsets with `@offset` so each lands on
  its filesystem magic. Read `/etc/dupfstab` in the rootfs to get the required order.
  ```
  qemu-system-arm -M ast2600-evb -m 1024 -nographic \
    -kernel kernel.Image -dtb board.dtb -initrd rootfs.sqfs \
    -drive file=mtdflash.bin,format=raw,if=mtd \
    -net nic -net user,hostfwd=tcp::PORT-:443,hostfwd=udp::PORT-:623 \
    -append "console=ttyS4,115200n8 root=/dev/ram0 ro rootfstype=squashfs \
             ramdisk_size=131072 mtdparts=<...> maxcpus=1 rootwait"
  ```
- Expect a `login:` in ~2 min; default MegaRAC console cred is often `sysadmin` / `superuser` (uid 0).

### 6. Network — check the kernel version FIRST
MegaRAC's ftgmac is usually **NC-SI** (`use-ncsi` in DTB). Important facts:
- **QEMU already implements the NC-SI responder internally** — it does NOT forward `0x88F8` frames to any
  netdev. So an *external* NC-SI responder is impossible; don't build one. Verify with a socket-netdev
  sniff (you'll see zero frames).
- Whether the link comes up is a **guest-kernel** property. Newer AMI kernels (~5.4.184) negotiate with
  QEMU's responder and get a slirp DHCP lease → SSH/Redfish/IPMI work. Older ones (~5.4.11) have a
  customised driver that forces NC-SI and rejects QEMU's response
  (`NCSI: Handler for packet type 0x82 returned -19`) → link never comes up.
- **Diagnose frame-traversal before trying fixes**: `ip addr add 10.0.2.15/24 dev eth0; ping 10.0.2.2`.
  TX errors / 100% loss = frames aren't leaving the MAC; stop editing the DTB and look at the kernel.
- Things that do **not** work on the older-kernel case (don't repeat): stripping `use-ncsi`, adding
  `fixed-link`, enabling the RGMII MAC, `usb-net` (AST2600 EHCI is high-speed-only → full-speed usb-net
  hangs). Booting the rootfs on a newer kernel gets link-up but then panics in `aspeed_udma_request_chan`
  (AMI `ast8250` serial driver hardcodes UART-DMA QEMU doesn't model).
- If you hit the older-kernel wall, ship the box **console-only** and treat network as a kernel-patch /
  custom-QEMU sub-project. Console access (root shell, all services) is still a complete local surface.

## Red flags (stop and rethink)
- "binwalk found nothing" → you skipped SquashFS; scan magics manually.
- IPMIMain crash-loops → you skipped the `/conf/BMC` symlink or left absent-hw interfaces enabled.
- eth0 "up" but nothing reachable → NC-SI/kernel wall; don't chase iptables or host ports.
- About to write an NC-SI responder → QEMU already has one; the issue is the guest kernel.
