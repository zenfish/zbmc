# From Firmware to Bare Metal: Virtualizing an AMI MegaRAC BMC under QEMU

A field report on taking a vendor BMC firmware image — the Advantech **ASMB-787**, an AMI
**MegaRAC SP-X 4.0** running on an **ASPEED AST2600** — from a single `.ima_enc` blob all the way to a
booting, root-shell-accessible virtual BMC under QEMU. It covers what worked, what didn't, and the
several walls we hit and how we got over (or around) them.

The goal was a *zoo denizen*: a virtual BMC you can `start`, `console` into, and poke at like a real
one — for security research on the OOB management stack (IPMI, Redfish, the web UI) without owning the
physical board.

> **TL;DR outcome:** full MegaRAC userland boots, IPMIMain is stable, all services (redis, lighttpd,
> Redfish, event/task) come up, and you get a **root console** (`sysadmin` / `superuser`). External
> network (SSH/Redfish/IPMI over host ports) is blocked by a kernel-driver-vs-QEMU incompatibility that
> is *fully diagnosed* below but needs kernel-level work to fix — so the box ships **console-accessible**.

---

## 0. Environment

Everything below ran on:

| Tool | Version |
|------|---------|
| Host | macOS (Darwin 25.5.0), Apple Silicon `arm64` |
| QEMU | `qemu-system-arm` **11.0.0** (Homebrew) |
| squashfs-tools | unsquashfs / mksquashfs **4.7** |
| u-boot-tools | dumpimage **2026.04** |
| jefferson | (pipx) — JFFS2 extractor |
| dtc | **1.7.2** (device-tree compiler) |
| binwalk | **3.1.0** |
| python | 3.x |

The target SoC (AST2600, dual Cortex-A7) maps to QEMU's **`ast2600-evb`** machine. That single fact —
that a vendor firmware built for the real AST2600 EVB reference platform lines up with an EVB machine
QEMU already models — is what makes this tractable at all.

---

## 1. The artifact: what a "firmware image" actually is

We started with two files:

```
encrypted_ASMB-787_20220912.ima_enc      67,109,128 bytes
BMC Firmware 0.84.zip                     15,894,550 bytes   (a neighbouring Advantech bundle)
```

`file(1)` misidentified the `.ima_enc` (it guessed "AmigaOS bitmap font" — ignore it). The name says
*encrypted*, and the `.ima_enc` extension screams AES. **It is not encrypted.** Two cheap checks proved
that immediately:

**Header** — the first bytes are an ARM exception-vector table plus U-Boot markers:

```
0f00 00ea 14f0 9fe5 14f0 9fe5 ...   ; b 0x44 ; ldr pc,[pc,#0x14] × repeated  (ARM vectors)
... 4000 0000 ...                    ; @ markers
... efbe adde ...                    ; 0xdeadbeef  (U-Boot/ASPEED)
```

**Entropy profile** (per-MB Shannon entropy) — an AES blob is ~8.0 bits/byte *everywhere*; this had
clear structure:

```
  0MB  H≈4.95  ####…      (U-Boot, plaintext)
  1–4  H≈0–2              (config / padding)
  5–44 H≈8.00  #########  (the "scary" high-entropy region)
 45–63 H≈0                (0xFF/0x00 flash erase padding)
   64  H≈7.24             (tail: a signing pubkey + module footers)
```

That 5–44 MB block at H=8.0 *looks* encrypted, and that's exactly the trap: it's **XZ-compressed
SquashFS**, not ciphertext. Compression and encryption both flatten entropy to ~8.0; the only way to
tell them apart is to find structure (magic bytes) inside.

### 1a. The format: AMI FMH

Scanning for `$MODULE$` (AMI's Flash Module Header signature) at 64 KB-aligned offsets reveals the
partition table baked into the image:

```
0x000c0000  conf      2048K   (jffs2, config)
0x002c0000  conf      2048K   (jffs2, the dual/golden copy = "bkupconf")
0x004c0000  root     32000K   (squashfs/xz, the main root fs)
0x02400000  osimage   4096K   (a U-Boot FIT: kernel + device trees)
0x02800000  www       6144K   (squashfs/xz, the web UI)
0x02e00000  dre      18432K   (jffs2, redfish/gami subextensions)
```

Each module's payload starts **0x10000 (one erase block) after** its `$MODULE$` header — so `conf`'s
JFFS2 data is at `0xD0000`, the root SquashFS is at `0x4D0000`, etc.

### 1b. Why binwalk lied — and the two extraction gotchas

Running the local `binwalk 3.1.0` on the image reported **"0 file signatures"** — nothing. But a
*prior* binwalk run had left an `.extracted/` dir with real JFFS2 trees. The lesson:

> **Gotcha #1 — never trust "binwalk found nothing."** A degraded/older signature DB silently skips
> SquashFS. We found the two SquashFS filesystems by scanning for the `hsqs` superblock magic ourselves,
> reading `bytes_used` from superblock offset `0x28` (u64 LE) to get the exact size, then carving and
> `unsquashfs`-ing. The 40 MB "encrypted" blob unpacked into a full BusyBox rootfs.

> **Gotcha #2 — jefferson auto-detects JFFS2 endianness *per file*.** Fed the whole 67 MB image it
> guesses **big-endian** and extracts **0 nodes**. Carve the single JFFS2 region out first (it's
> little-endian) and jefferson finds all 90 inodes. There is no `--little-endian` flag; isolation is the
> fix. All of this is codified in [`tools/unpack-ami`](../tools/unpack-ami).

The result: `unpack-ami firmware.ima_enc` → `rootfs/` (2303 files), `www/` (99), `conf`/`subext` JFFS2
trees, the FIT, and a signing public key — in ~35 s. **The "encryption" was a filename, nothing more.**

---

## 2. First contact: does the kernel even boot?

Before any userland, the cheapest possible test — boot the *raw* image as an MTD flash and watch
U-Boot / the kernel come up. The kernel and DTB live inside the `osimage` FIT (`d00dfeed` magic at
`0x2400040`), and **QEMU's `-kernel` cannot unpack a FIT**, so we pull the raw pieces out with
`dumpimage`:

```bash
dumpimage -l osimage.itb                 # list: image 0 = "Linux kernel" (load 0x80001000),
                                         #       image 1 = fdt ast2600evb_a1.dtb
dumpimage -T flat_dt -p 0 -o kernel.Image osimage.itb
dumpimage -T flat_dt -p 1 -o dtb-a1.dtb   osimage.itb
```

Kernel is **Linux 5.4.11-ami** (armv7l). First boot attempt:

```bash
qemu-system-arm -M ast2600-evb -m 1024 -display none \
  -kernel kernel.Image -dtb dtb-a1.dtb -initrd rootfs.sqfs \
  -drive file=mtdflash.bin,format=raw,if=mtd \
  -append "console=ttyS4,115200n8 root=/dev/ram0 ro rootfstype=squashfs \
           ramdisk_size=131072 maxcpus=1 rootwait init=/bin/sh"
```

Two things to note in that command line, both learned the hard way:

- **`console=ttyS4`** — the AST2600 wires the console to UART5, which Linux calls `ttyS4`. Point it at
  `ttyS0` and you get a silent boot.
- **`maxcpus=1`** — the EVB is dual-core but CPU1 bring-up faults under emulation; cap it in the kernel.

### Wall #1 — the flash chip size must be *exact*

```
qemu-system-arm: w25q512jv device ... requires 67108864 bytes,
                 mtd0 block backend provides 67109128 bytes
```

QEMU's `m25p80` model of the AST2600 FMC flash (`w25q512jv`, 512 Mbit = **exactly 64 MiB**) refuses a
backing file that isn't precisely that size — and the `.ima_enc` is 264 bytes over. Fix: truncate the
flash copy to `0x4000000`. (Those trailing bytes are module-footer padding; nothing boot-relevant.)

```bash
truncate -s 67108864 mtdflash.bin
```

With that, the kernel boots to a root shell in **~5 seconds**:

```
Platform ASMB-787
VFS: Mounted root (squashfs filesystem) readonly on device 1:0.
Run /bin/sh as init process
/ #
```

That single result collapsed most of the risk: kernel boots, our carved rootfs mounts, the board
self-identifies. Everything after this is userland bring-up.

---

## 3. Real init: making MegaRAC actually run

`init=/bin/sh` is a shell, not a BMC. Swapping to `/sbin/init` runs the full sysvinit stack — and that's
where MegaRAC's central daemon, **IPMIMain**, comes in. It reliably **SIGSEGV'd and reboot-looped**.

This exact failure had been solved before on a sibling box (the HPE Cray XD670, same MegaRAC SP-X /
`ast2600evb_ami` platform), via Ghidra RE. The two fixes ported cleanly and live in
[`box/qemu-patch-rootfs.sh`](../box/qemu-patch-rootfs.sh):

**Fix 1 — the `/conf/BMC` symlink.** IPMIMain opens the *literal* path `/conf/BMC/IPMI.conf` to build
its per-interface state table `g_BMCInfo[]`. On real hardware, platform detection creates
`/conf/BMC → BMC1/ast2600evb_ami`. Nothing does that under QEMU, so the table never builds and the
central message handler dereferences an uninitialised field → SIGSEGV → procmgr respawns → 15 crashes →
BMC reboot. We inject a seed block into `etc/init.d/ipmistack` (before every IPMIMain launch) that
seeds `/conf` from `/etc/defconfig` and creates the symlink, gated on a `/conf/AMI` sentinel so it's
idempotent across respawns.

**Fix 2 — trim `IPMI.conf` to the hardware QEMU actually models.** The EVB gives us LAN (eth0), a Unix
domain socket, and KCS1–3 — but **no** SOL/serial DMA, no i2c (so no IPMB/SMBUS), no SMM config file.
Each enabled-but-absent interface leaves a half-initialised table entry that the message-handler thread
later derefs → SIGSEGV. Ghidra RE of `IPMIConf.c` also turned up a Node-Manager guard that self-stops
unless `NM_IPMB_BUS` is 0/1/2 *and* that bus is enabled. So the patch sets:

```
SUPPORT_SMM_IFC=0   SUPPORT_SOL_IFC=0   (SERIAL/SMBUS/BT/IPMB already 0 in ASMB defconfig)
NM_IPMB_BUS=0xFF    (>=3 falls through the guard -> Node-Manager doesn't self-stop)
```

Keep LAN, UDS, KCS. With both fixes IPMIMain runs stable, provisions the default `sysadmin`/`superuser`
user into a clean `/conf`, and the whole stack comes up:

```
Starting redis-server ... Starting Redfish Server ... Redfish PAM Authentication Service ...
Launching Event-Service ... Launching Task-Service ... Interface eth0 is up ...
AMI525400123458 login:
```

### Wall #2 — mounting `/conf` from the right MTD blocks

MegaRAC's compiled `/usr/local/bin/mountallapp` mounts partitions **by `/dev/mtdblockN` number**, driven
by `/etc/dupfstab`:

```
/dev/mtdblock1   /conf            jffs2
/dev/mtdblock3   /usr/local/www   squashfs
/dev/mtdblock4   /dre             jffs2
```

So the *ordering* of our `mtdparts=` matters, not just the names — and each partition must land exactly
on its filesystem's magic. Because our `mtdflash.bin` **is** the real linear NOR (unlike the Cray box,
whose source was a non-linear HPM wrapper), we can point partitions at the true data offsets with the
`@offset` syntax:

```
mtdparts=1e620000.spi:832k@0(uboot),1984k@0xd0000(conf),1984k@0x2d0000(bkupconf),\
6144k@0x2810000(www),-@0x2e10000(dre)
```

`mtdblock1`=conf lands on the JFFS2 at `0xD0000`, `mtdblock3`=www on the SquashFS at `0x2810000`, and so
on — matching `dupfstab` exactly. `/conf` mounts read-write, the seed runs, IPMIMain provisions its user.

At this point: **`zbmc asmb787 console` → login `sysadmin`/`superuser` → uid 0 root shell.** Everything
local works.

---

## 4. Wall #3 — the network. The long one.

Every remote service (SSH:22, Redfish:443, IPMI RMCP+:623) rides `eth0`. And `eth0` would not pass a
single frame to QEMU's user-mode network (slirp). The host-side TCP even *connects* (slirp accepts
locally) but SSH dies at "banner exchange" — the guest never answers. This took the longest and went
through the most wrong turns, so here's the full arc.

### The symptom

```
ftgmac100 1e670000.ftgmac eth0: Using NCSI interface
ftgmac100 1e670000.ftgmac eth0: NCSI: No channel found to configure!
```

**NC-SI** (Network Controller Sideband Interface, DMTF DSP0222) is how a BMC shares the host's physical
NIC. The BMC MAC negotiates with the NIC over EtherType `0x88F8` control packets (Get Version, Get
Capabilities, Select Package/Channel, Get Link Status, Enable Channel) before any data flows. Our MAC
(`ftgmac@1e670000`, marked `use-ncsi` in the DTB) waits on that negotiation, finds no channel, and
never brings the link up.

### The wrong turns (recorded so you can skip them)

| Attempt | Flags / edit | Result |
|--------|--------------|--------|
| Manual static IP + route | `ip addr add 10.0.2.15/24; ip route add default via 10.0.2.2` | link "up" but ping gw = 100% loss / TX errors |
| Flush firewall | `iptables -F; iptables -P INPUT ACCEPT` | no change — not a filtering issue |
| Strip `use-ncsi` from DTB | `dtc` edit, recompile | driver *still* does NC-SI |
| Add `fixed-link` to the MAC | `fixed-link { speed=<100>; full-duplex; }` | carrier=1, but frames still don't traverse |
| USB-net (idrac9 trick) | `-device usb-net,netdev=n0,bus=usb-bus.0` | **QEMU hangs** — AST2600 EHCI is high-speed-only, `usb-net` is full-speed → speed mismatch |
| Enable the RGMII MAC | `1e660000` `status="okay"`, disable `1e670000` | eth0 moves to the phy-backed MAC but driver *still* forces NC-SI |

A lot of that was chasing NC-SI as "the thing to disable." Two facts finally reframed it:

**Reframe A — QEMU already *is* the fake NIC.** Wire a socket-netdev straight to the ftgmac and sniff:
**zero frames** arrive while the kernel is doing NC-SI. QEMU's ftgmac model **handles NC-SI internally**
and never forwards those `0x88F8` frames to any backend. So building an *external* NC-SI responder is
impossible — there's nothing to answer. (This killed our planned "fake NIC" daemon before we wrote it.)

**Reframe B — it's the guest kernel, not the emulator.** The sibling Cray box uses the *same* QEMU, the
*same* `-net nic -net user`, a DTB with the *same* `use-ncsi` — and it gets a DHCP lease and serves
Redfish. The only difference is its kernel: **5.4.184-ami**. Its ftgmac driver negotiates with QEMU's
built-in responder and brings the link up. ASMB-787's **5.4.11-ami** driver is AMI-customised (it prints
`This NCSI chip not support Keep-PHY linkup`), **forces NC-SI regardless of the DTB**, and its handler
*rejects* QEMU's response:

```
ftgmac100 1e660000.ftgmac eth0: NCSI: Handler for packet type 0x82 returned -19   (-ENODEV)
```

So the wall is a **kernel-driver ↔ QEMU-responder protocol mismatch**, kernel-side, in an older AMI
build. No DTB tweak, external responder, or USB-net gets around it.

### The last lead — swap in the working kernel

If 5.4.184 negotiates fine, boot ASMB-787's *rootfs* on the **Cray kernel**. It got further than anything
else — `eth0: Link is Up - 100Mbps/Full` on the RGMII MAC (`1e660000`) — then panicked:

```
PC is at aspeed_udma_request_chan+0x1f8   <- ast8250_startup -> aspeed_udma_request_tx_chan
Unhandled fault: page domain fault ... Comm: stty
```

The AMI **`ast8250` serial driver hardcodes UART-DMA**; QEMU doesn't model that DMA. When ASMB-787's
init runs `stty` on a serial, the 5.4.184 kernel dereferences a NULL channel → panic. Disabling the
`uart-dma` node and stripping `dmas` from the DTB didn't help — the driver ignores the DTB and calls
`request_tx_chan` unconditionally. Cray's own rootfs never opens that serial, so Cray never hits it.

That's the shape of it: the AMI 5.4.11 stack fights QEMU at **two** layers in sequence — **NC-SI
(ftgmac)**, then **UART-DMA (ast8250)** — and clearing one exposes the next, on top of 5.4.184-vs-5.4.11
module skew. Each is individually solvable with kernel binary-patching or a custom QEMU build; none is a
one-liner.

### The compromise

We shipped the box **console-only**. It's a legitimate denizen — the sibling Cray box's *primary*
documented access is also its console. Root shell, all services live, full local attack surface. The
remaining paths to network (any one of: binary-patch the ftgmac/ncsi handler in the kernel Image;
rebuild QEMU's ftgmac NC-SI to satisfy the AMI handler; de-panic the Cray kernel by neutralising every
DMA-serial open in ASMB-787's init) are documented as a parked, multi-session sub-project.

---

## 5. What you end up with

```
tools/unpack-ami            one-command AMI MegaRAC unpacker (the gotchas above, codified)
tools/zbmc                  the "zoo" dispatcher: zbmc <box> start|console|status|...
box/qemu-patch-rootfs.sh    the two IPMIMain fixes (conf/BMC symlink + IPMI.conf trim)
box/boot-asmb787-svc.sh     the exact QEMU invocation (mtdparts, ttyS4, hostfwd)
box/build.sh                firmware -> {kernel.Image, dtb, rootfs.sqfs, mtdflash.bin} in ~35s
box/zbmc.box               the box descriptor (creds, ports, verbs)
firmware/…ima_enc           the source of truth
```

Quickstart:

```bash
./box/build.sh                       # regenerate artifacts from the firmware
WD=./work BG=1 ./box/boot-asmb787-svc.sh
tail -f ./work/svc.log               # login: sysadmin / superuser  (uid 0)
```

## 6. Lessons worth carrying to the next BMC

1. **"Encrypted" is often a filename.** Check the header and entropy *profile* before believing it.
   Compression and encryption both read ~8.0 bits/byte; only structure distinguishes them.
2. **Don't trust "binwalk found nothing."** Scan filesystem magics (`hsqs`, `0x1985`, `d00dfeed`)
   yourself; carve by the size field in the superblock.
3. **jefferson picks JFFS2 endianness per file** — isolate the region first.
4. **Match the emulator's exact hardware:** flash chip size to the byte, console UART, single-CPU cap,
   and only the IPMI interfaces the machine actually models.
5. **Mount by the firmware's own rules** — read `/etc/dupfstab`; partition *order* (mtdblock numbers)
   can matter more than names.
6. **Diagnose frame-traversal before trying network fixes.** One `ping <gateway>` that shows TX errors
   would have saved hours of DTB edits. Prove where the frames stop first.
7. **The emulator may already implement the sideband.** We nearly built an NC-SI responder QEMU didn't
   need — a socket-netdev sniff (zero frames) proved QEMU answers NC-SI itself. The real variable was the
   guest kernel version.

*Written up from a live RE session (2026-08). Sibling boxes in the same "zoo": HPE Cray XD670
(MegaRAC SP-X, networked), Supermicro X14 (OpenBMC), Dell iDRAC9/10 (NPCM).*
