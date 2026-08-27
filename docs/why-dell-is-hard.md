# Why the Dell iDRACs Are Hard (and how the turnkey boxes cheat)

> **Historical field note.** The snapshot conclusions below describe an earlier investigation state.
> Current release behavior is different: iDRAC9 is cold-only, and iDRAC10 now cold-boots by default from
> fetched artifacts, deterministically generated cfgdb defaults, and a per-installation SSH key. The old
> shared iDRAC10 checkpoint is no longer fetched or accepted by `start --warm`. See `README.md` and
> `SECURITY.md` for the current contract.

A field note on failure. The OpenBMC boxes in this zoo (`openbmc`, `nvidia-obmc`) boot in one command;
the Dell iDRACs took weeks. This preserves why earlier snapshot-first approaches were attempted and what
they taught us; it is not the current operator guide.

## The turnkey boxes cheat

An OpenBMC image is **one flash blob** — u-boot + kernel + rootfs concatenated — and it boots on a stock
QEMU machine with `-drive if=mtd,snapshot=on`. Nothing to assemble, deterministic, done in ~2 minutes.
That's the whole trick behind `openbmc` and `nvidia-obmc`.

The iDRACs break **every** assumption in that sentence.

## iDRAC, in general

1. **No flash-boot.** The vendor SPL → u-boot → secure-boot/ROT chain won't complete under emulation
   (no TrustZone/OP-TEE/CPLD model). So you can't boot the flash image — you must **direct-kernel** boot:
   carve the kernel, DTB, initrd, and rootfs out of the DUP's `firmimg` (a U-Boot FIT), patch, reassemble.
2. **`CONFIG_CMDLINE_FORCE`.** The iDRAC kernel **ignores `-append`** — its compiled-in bootargs win. You
   can't just pass `root=`/`console=`/`init=`. You either own the initramfs, or **binary-patch the kernel**
   to blank the forced args.
3. **rootfs on the SD bus.** It must attach as a block device on the SDHCI controller
   (`-drive if=none,file=… -device sd-card,bus=sd-bus` → `mmcblk0`), **padded to a power-of-2** size.
   Generic `-sd`/`if=sd` is rejected; the SDHCI node must be in the (minimal) DTB or the kernel panics
   "Cannot open root device".
4. **A proprietary Dell service mesh**, not stock systemd/Phosphor. Bringing it up clean is far fussier
   than "let systemd start everything."
5. **IPMI auth is a key, not a password** (see below).

Any one of these is a speed bump. iDRAC10 hits all of them at once.

## iDRAC10 — the boss fight (NPCM845 / aarch64)

- **Different architecture.** `qemu-system-aarch64 -M npcm845-evb` — nothing from the ARMv7 boxes carries
  over.
- **4 binary kernel patches** just to boot: blank the forced `quiet`, bump `loglevel 0→8`, inject
  `root=/dev/mmcblk0 … init=/usr/bin/sh` (the shell is `/usr/bin/sh`, not `/bin/sh`).
- **The dbus-broker socket-activation lottery.** Cold boot **hangs roughly 2 times in 3** under a single
  TCG vCPU — nondeterministically. This is the real killer: you cannot ship a `build.sh` that "just boots"
  when a third of boots wedge.
- **Historical snapshot path.** Cold-boot *retrying until services + IPMI answer*, then QMP
  `stop` + `migrate exec:gzip` → `state.gz`. Restore with `-incoming` over a **frozen qcow2 overlay**
  (NOT `snapshot=on` on the base, or the disk and the migrated RAM diverge and it corrupts). On resume you
  must **loop QMP `cont` until the vCPU reports `running`** — a single `cont` leaves it half-migrated with
  the network silent. Then verify IPMI and **re-restore up to 3×** (a migrated UDP socket sometimes
  resumes silent — the host port is bound but the guest never answers).
- **Encrypted RAKP.** The login handshake was cracked two ways: an `shm-shim` `LD_PRELOAD` interposing on
  the session library, and (more durably) a real `cfgmgrd` fed a seeded `CfgCurrentValues.db` (username
  must be 16-byte `MemCmp`-padded, the privilege nibble lives at a raw offset, the HMAC key at entry+0x11).

That approach explained the earlier snapshot bundle. The current package deliberately does not fetch it:
ordinary `zbmc idrac10 start` cold-boots, while `start --warm` fails with an explicit unsupported message.

## iDRAC9 — one notch easier, one notch worse

ARMv7 (NPCM750), so no aarch64 tax, and it **boots and networks fine cold** — you can ssh straight in.
Its curse is narrow and specific: **the only NIC that works is the one that can't survive a warm restore.**
The npcm750 offers three NICs and every one fails a different way (all live-verified, qemu 11.0.0):

| NIC | binds in guest? | works cold? | survives `-incoming`? | how it fails |
|-----|-----------------|-------------|-----------------------|--------------|
| `usb-net` (cdc_ether → `usb0`) | yes | **yes** (ssh up in ~117 s) | **no** | EHCI async RX URBs don't resume; stock qemu marks it `.unmigratable=1`. A `net-selfheal` service in the initramfs bounces the iface on RX-stall — that loop exists *because* this path is fragile. |
| on-chip EMC (`npcm7xx-emc` → `eth2`) | **yes** (probes clean, Generic PHY) | **no** | — | binds DOWN; the instant you bring it up and pass a packet: `BUG: spinlock bad magic … PC is at 0x0 … Kernel panic — Fatal exception in interrupt`. Dies in `ksoftirqd`, takes `usb0` down with it. |
| on-chip GMAC (`npcm-gmac`) | no | — | — | driver hands phylink a NULL `validate` cb → `phylink_validate+0x18` PrefetchAbort, kernel jumps to 0 on link-up. |

So iDRAC9's warm restore comes back **network-dead**: the snapshot is captured on `usb-net` (the only cold-
working NIC), and `usb-net` is exactly the one that doesn't re-enumerate on resume. The on-chip NICs that
*would* migrate cleanly (like iDRAC10's gmac does) either panic on traffic (EMC) or crash on link-up (GMAC).
The snapshot gives you the box for console/inspection; external IPMI/ssh need a (flaky) cold boot. Awkward
middle child.

### Tested and ruled out: "was it a qemu regression? try qemu 9/10"

A reasonable hunch — maybe an older qemu modelled the NPCM NICs differently and one of them survived
migration. **It isn't a version regression.** I have qemu `9.1.1`, `10.0.2`, `10.0.3`, and `11.0.0` side by
side; `-M npcm750-evb` attaches the **same four on-chip NICs on every one** (2× `npcm7xx-emc` + 2×
`npcm-gmac`), and the EMC `spinlock bad magic → PC 0x0` panic reproduces regardless of qemu version. The
`usb-net` `.unmigratable=1` flag has been a standing property across releases, not something that regressed.
Downgrading qemu changes nothing — 10.0.3 and 11.0.0 present iDRAC9 identical hardware and the guest reacts
identically. **The wall is guest-side** (kernel driver + DTB + an initramfs hardwired to the USB-CDC iface),
so the real fix lives there, not in the qemu version: make an on-chip NIC pass traffic without panicking,
then capture the snapshot on *that* NIC. Same effort on any qemu.

## Why `ipmitool` fails and only `zipmi -K` works

RMCP+ (IPMI 2.0) logs in via **RAKP**: the client proves it knows the user's key by HMAC'ing the handshake.
Normally that key **is the password** (ASCII, null-padded to 20 bytes) — `ipmitool -P calvin` HMACs with
`"calvin\0…"`.

But an iDRAC user's stored credential isn't a hashed password — it's a **raw 20-byte binary `IPMIKey`**
(the fleet-shared factory key, e.g. `915F32…`). The BMC HMACs the RAKP messages with **those 20 bytes**.

So `ipmitool -P calvin` HMACs with the wrong key → RAKP2 integrity check fails → *"Unable to establish
session."* `calvin` is the **web/racadm** password; it has nothing to do with IPMI. `zipmi -K 915f32…`
supplies the **raw hex key** directly as the RAKP HMAC key → it matches → session up. ipmitool has no flag
to substitute a raw binary user key for the password (its `-k` is the *Kg* "BMC key", a different RMCP+
parameter). Hence a tool like `zipmi` is required.

**The finding:** iDRAC ships **one fleet-shared 20-byte IPMIKey per generation**, extractable from the
public DUP, identical on every factory/reset unit — so whoever has it authenticates as root over IPMI to
any of them, no password. iDRAC9 and iDRAC10 share the same (unrotated) key.

## racadm

Dell's native CLI — a **different protocol** than IPMI, and it uses the **web password (`calvin`)**, not
the IPMIKey. `racadm -r <ip> -u root -p calvin getsysinfo` (remote), or `racadm getsysinfo` (local, inside
the guest — the iDRAC ships it). Status in this repo: the binary *runs* in-guest, but the IPMI-focused
snapshot returns `RAC1135` (its data-services "instrumentation" isn't fully up). A full-mesh (P3/P5)
snapshot, or the remote/docker path against one, is needed to actually exercise it — **open item**.

## The open improvement: build-from-DUP

Shipping warm snapshots is v1 pragmatism, and it's fragile — a snapshot restores **only on the exact QEMU
it was captured with** (change the build → "Missing section footer" on restore). The real prize is a
`build.sh` that goes DUP → boot artifacts → *reliable* boot, without a snapshot:

- Beat the **dbus-broker lottery** deterministically (find the racing socket-activation unit and order it,
  or mask it and hand-start the target).
- Reproduce the **4 kernel patches** from the DUP's kernel (they're mechanical byte-patches).
- Seed the **RAKP DB** at build time instead of interposing at runtime.

If you make any iDRAC boot reliably from firmware, that box graduates from `snap` to a true from-source
turnkey. The recipes and findings under `boxes/idrac9/` and `boxes/idrac10/` (plus
[zoo-lessons.md](zoo-lessons.md)) are the map. Someone more skilled than this first pass can absolutely
make them better — that's the point of writing the wall down.
