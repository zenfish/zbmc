# Why the Dell iDRACs Are Hard (and how the turnkey boxes cheat)

A field note on failure. The OpenBMC boxes in this zoo (`openbmc`, `nvidia-obmc`) boot in one command;
the Dell iDRACs took weeks and still only run from a **warm snapshot**, not from firmware. This documents
*why* — because the wall is more instructive than the win, and because the path to doing it "properly"
(build-from-DUP) is wide open for anyone who wants it.

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
- **Warm snapshot is the only reliable path.** Cold-boot *retrying until services + IPMI answer*, then QMP
  `stop` + `migrate exec:gzip` → `state.gz`. Restore with `-incoming` over a **frozen qcow2 overlay**
  (NOT `snapshot=on` on the base, or the disk and the migrated RAM diverge and it corrupts). On resume you
  must **loop QMP `cont` until the vCPU reports `running`** — a single `cont` leaves it half-migrated with
  the network silent. Then verify IPMI and **re-restore up to 3×** (a migrated UDP socket sometimes
  resumes silent — the host port is bound but the guest never answers).
- **Encrypted RAKP.** The login handshake was cracked two ways: an `shm-shim` `LD_PRELOAD` interposing on
  the session library, and (more durably) a real `cfgmgrd` fed a seeded `CfgCurrentValues.db` (username
  must be 16-byte `MemCmp`-padded, the privilege nibble lives at a raw offset, the HMAC key at entry+0x11).

That's why `boxes/idrac10` ships a **snapshot bundle** (kernel + gmac DTB + 256 MB SD image + frozen
overlay + 71 MB RAM state) fetched from the mirror, and `vbmc idrac10 start` does restore-not-build.

## iDRAC9 — one notch easier, one notch worse

ARMv7 (NPCM750), so no aarch64 tax. But its on-chip GMAC/EMC **NULL-crashes** the kernel on link-up, so it
falls back to **`-device usb-net`** — which works, but **does not re-enumerate after `-incoming`** (EHCI
async URBs don't resume). So iDRAC9's warm restore comes back **network-dead**: the snapshot gives you the
box for console/inspection, but external IPMI/ssh need a (flaky) cold boot. It's the awkward middle child.

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
