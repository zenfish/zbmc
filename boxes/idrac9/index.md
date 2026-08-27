<!-- html2md:auto source=boxes/idrac9/index.html source-sha256=cab351670fc68e519df2cb10f23c25e2b46832264028abe682c6b3c2a908561c body-sha256=666477039278a6b1f6e59f67d07d64e5e943c56abc2b79d22bb5d87597228ce9 -->

**Historical investigation record.** The phase roadmap below predates zbmc 0.1.1. Current iDRAC9 cold-boots to accepted ICMP, SSH, IPMI, and vendor Web-UI in 10m31s on the reference host; Redfish remains unavailable. Use the repository README and `./tools/zbmc idrac9 status -v`.

# Virtual iDRAC9 — Dell's BMC firmware under QEMU

*Goal: a working, explorable iDRAC9 in software — boot Dell's own kernel + rootfs on QEMU's Nuvoton `npcm750-evb` machine, climb from a shell up toward a live appliance (racadm / RAKP / web). SoC: Nuvoton **NPCM750** (Poleg, ARMv7 dual Cortex-A9). Firmware: `firmimgFIT.d9` 7.20.30.50, kernel `Linux 5.4.80.idrac`.*

**Status — SSH ROOT LOGIN WORKS (2026-06-22).** Three boot modes, all working: `./run.sh` = Phase-1 shell + chroot; `./run-p2.sh` = Phase-2 full systemd boot of the real daemon stack; `./run-p3.sh` + `./ssh-in.sh` = Phase-3 minimal bring-up you can **SSH into as root** (uid=0, real `racadm` binary); `./run-p4.sh` = Phase-4, the daemon mesh up under systemd with **LIVE racadm** (full command pipeline: object-model + instrumentation + auth — §7). The kernel/driver walls (a dm_bufio panic, a phylink NIC crash) were cracked with gdb on the live gdbstub. Remaining: attribute *values* (cfgdb seed) and RAKP/`fullfw` (needs an NPCM hardware shim).

## 1 · What works now

    $ ./run.sh
    ######## VIRTUAL iDRAC9 — initramfs ALIVE ########
    uname: Linux (PolegDRB) 5.4.80.idrac #1 SMP ... armv7l GNU/Linux
    rootfs mounted from /dev/mmcblk0
    === PROOF: run a real rootfs binary via chroot ===
      in-rootfs uname: armv7l
      racadm bin: -rwsr-sr-x 2 root root 6704 /usr/bin/racadm
      os bin:     -rwxr-xr-x 1 root root 231096 /usr/bin/os
    / # chroot /newroot /bin/sh      # ← explore the real iDRAC9 userspace

## 2 · The recipe (and the four traps that cost the most)

1.  **Artifacts** come from the FIT kernel image `md.itb`: `zImage` (ARM, XZ piggy, entry 0x8000), the *base* device tree (`model="iDRAC"`, `compatible="nuvoton,npcm750"`), and the first-stage initramfs. Extract with `dumpimage -T flat_dt -p N -o … md.itb`. See `build.sh`.
2.  **Trap 1 — the console UART is on serial@1000.** QEMU models NPCM750 UARTs at `0xf0001000…0xf0004000`; the *first* `-serial` maps to `0xf0001000` = Dell's `ttyS0`. (`-nographic` silently steals serial-0 to stdio and bumps your `-serial` to UART1 — don't use it; use `-display none -serial stdio`.)
3.  **Trap 2 — `CONFIG_CMDLINE_FORCE`.** The kernel ignores `-append` entirely and uses its built-in cmdline: `console=ttyS0,115200n8 … `**`quiet loglevel=0`**` … `**`init=/init`**` rdinit=/init blkdevparts=mmcblk0:…`. So *(a)* kernel boot messages are suppressed (`quiet`) — silence is not a hang; *(b)* you cannot change the console or init via the command line.
4.  **The lever:** `init=/init` runs the *initramfs* `/init`, which we fully control (it's the `-initrd`). We replace it (see `init.custom`) to skip the eMMC + dm-verity dance, mount the rootfs squashfs, and drop to a shell. No kernel patching, no signed-FIT rebuild.
5.  **Trap 3 — the rootfs must be a block device.** Attach the squashfs to the SDHCI `sd-bus`: `-drive id=rootsd,if=none,file=…,snapshot=on -device sd-card,drive=rootsd,bus=sd-bus`. It appears as `/dev/mmcblk0`. (Generic `if=sd`/`-sd` are rejected by this machine.)
6.  **Trap 4 — SD size must be a power of two.** Pad the 177 MiB squashfs to 256 MiB (`truncate -s 256M`); squashfs ignores the trailing bytes. dm-verity is bypassed simply by mounting the raw squashfs read-only (verity only adds integrity checking).

## 3 · Files

- `run.sh` — boot to an interactive shell (Phase 1). `build.sh` — rebuild all artifacts from the firmware (idempotent).
- `init.custom` — the replacement initramfs `/init`.
- `boot/` — `zImage`, `base.dtb`/`.dts`, `initramfs.custom.xz` (regenerable; git-ignored binaries). `img/sd256.img` — padded rootfs SD image (git-ignored, 256 MiB).
- `scripts/trim-dtb.py` — disable DT nodes QEMU doesn't model (used while diagnosing; not needed for Phase 1 since the kernel reaches userspace on the unmodified base DT).

## 4 · Roadmap to a full appliance

| Phase | Milestone | Key work / bypass | State |
|----|----|----|----|
| 1 | Kernel boots → shell; explore + run real binaries | custom initramfs `/init`; squashfs on `sd-bus`; raw-mount (no verity) | **done** |
| 2 | Real `switch_root` → systemd → real daemon stack | `run-p2.sh`: patched kernel (dm_bufio NOP) + single-CPU DTB + masked Dell crash/reboot watchdogs (§5) | **done — boots cfgdb/sshd/oauth/iptables/net stably** |
| 3 | Networking + **SSH root login** | `run-p3.sh`: minimal init; EMC NIC (not the crashing GMAC, §6); sshd + host keys; files-only nsswitch → pubkey login. `ssh-in.sh` | **done ✅** |
| 4 | **LIVE `racadm`** | mesh as systemd services (datamgr→populators→SMIL) + cfgmgr Type=simple + /flash-writable + `RACADM_ACCESS=0x1FF` auth (§7). Command pipeline works end-to-end; attribute *values* still need a cfgdb factory seed. | **done ✅** |
| 5 | Live RAKP / IPMI | NPCM hw is modeled (msgbox/KCS/LPC/OTP present). `sensord` fixed (stage `bmcsetting`) → fullfw reads 350 SDR recs + monitor thread, then a **timing-race SEGV** in IPMI-channel setup; then `zipmi -K` vs `915F32…` | next (fullfw race) |
| 6 | HTTPS web UI / Redfish | apache `httpd -D SSL`, fcgi-racadm, dellwsmand, oauthd; fleet TLS host.key + oauth shared.key from `/flash/data0` | — |

### Known hard blockers past Phase 1 (from QEMU source + boot dissection)

- **No KCS/LPC host interface, no TPM, no eMMC-RPMB-as-secure-store, no Dell msgbox/SRAM** in QEMU's npcm model — these gate the host-side IPMI channel and some daemons; they must be stubbed or their consumers neutered.
- **A9 has no generic timer** — the kernel pokes `CNTVCT` (QEMU flags it "unsupported AArch32 64-bit sysreg"); harmless so far (it fell through to a working timer, since the kernel reaches userspace), watch if scheduling misbehaves under full load.
- Sensors/PECI/PWM/video unmodeled → thermal & sensor daemons will read zeros once up.

## 5 · Phase 2 — full systemd boot (SOLVED with gdb)

`run-p2.sh` `switch_root`s into the rootfs and lets **systemd** run the real stack (cfgdb, sshd keygen, oauth, iptables, network, power driver). Three walls, three fixes:

1.  **dm_bufio 30-s timer panic (~31.8 s).** A deterministic `__queue_work` oops on a corrupt per-CPU pointer. gdb on the live gdbstub read the static `work_struct` → `work.func = dm_bufio`'s cleanup worker (its 30-s `DM_BUFIO_WORK_TIMER_SECS` timer). **Fix:** NOP both `queue_delayed_work_on` schedule sites in the decompressed kernel (`scripts/patch-kernel.py`), boot it as a `uImage` (`-C none`, no zImage rebuild). dm_bufio is pulled in once a dm-verity client exists.
2.  **Systemic per-CPU workqueue corruption** (dm_bufio, srcu, …all crash the same way) is **CPU1-specific** under qemu npcm750 → boot **single-CPU** (`boot/p2uni.dtb`, `cpu@1` removed). Clears all of them.
3.  **Dell bail/reboot watchdogs** — `idrac-final` literally `echo c > /proc/sysrq-trigger`; `imon`/`*_recovery` reboot-loop when their SPI/eMMC checks fail off a real chassis. Mask the set (via `/run/systemd`) + set `panic_on_oops=0`. → **0 crashes, 0 reboots.**

Hardware gaps (KCS/TPM/RPMB/msgbox/sensors) are tolerated via guards/timeouts — they are not the wall. The walls were the dm_bufio timer and the per-CPU/SMP issue, both now handled.

## 6 · Phase 3 — minimal init + SSH root login (the usable box)

`run-p3.sh` skips systemd entirely. The custom `/init` (`init.p3.custom`) mounts the rootfs, fabricates the eMMC/SPI persistence layer with tmpfs (the real cause of the earlier *cfgdb* failure was dangling `/mnt/persistent_data` + `/flash/data1` symlinks, **not** hardware), seeds `/etc/machine-id`, then brings up only what we want. Results: `CfgDBInit completed successfully`; **sshd listens on :22**.

**Networking — the GMAC trap (found with gdb).** `ip link set eth0 up` silently killed the kernel. gdb caught it: kernel `die`, `saved_pc=0` (jumped to NULL), `saved_lr = phylink_validate+0x18` — the npcm **GMAC** driver hands phylink a **NULL validate callback**. The npcm **EMC** interface uses old phylib (no phylink) *and* is the one qemu's `-nic` peers to slirp → bring up `eth2` (EMC): `ping gw 0%% loss`, full SSH KEX, `OpenSSH_9.9` banner.

**Login — the avct trap.** iDRAC's `nss_avct` (nsswitch `passwd: avct files`) hijacks the root lookup → forces the racadm shell + mesh-coupled auth, rejecting a valid key. Bind a **files-only `/etc/nsswitch.conf`** over the read-only one → root = `/bin/sh`, plain pubkey auth (key in `/run/authkeys/root`, `UsePAM=no`, `StrictModes=no`).

    $ ./run-p3.sh          # boot (one terminal)
    $ ./ssh-in.sh          # root shell (another)
    uid=0(root) gid=0(root) groups=0(root)   Linux 5.4.80.idrac armv7l

## 7 · Phase 4 — the daemon mesh: **LIVE racadm** (SOLVED)

racadm is a client of Dell's D-Bus + ZeroMQ object model plus the DSM-SA instrumentation layer. The working approach: boot a custom `mini.target` (`DefaultDependencies=no`, no 200-service storm), get dbus serving, then **start the mesh as systemd *services*** via `systemctl --no-block start dsm-sa-datamgr.service` (pulls just the dep closure cfgmgr→dfserver/aim). `init.p4.custom` + `run-p4.sh` / `build-p4.sh`, `boot/p4.dts` (GMAC-off / EMC-only / single-CPU). Each blocker was found by stracing the failing daemon to the console; the box stayed stable throughout (24 s–5 min boots).

**The chain, in the order it was cracked:**

1.  **dbus-broker `-131`** = `error_fold()` folding a positive high-level error into `-ENOTRECOVERABLE` — *not* the broker spawn (earlier theory). The config parser `readdir`s `/etc/dbus-1/system.d`; two entries (`apphandler.conf`, `legacydfsfp.conf`) are symlinks into `/run/etc/…` that `systemd-tmpfiles` normally materializes from `/usr/share/factory` — `mini.target` skipped tmpfiles → dangling → ENOENT → exit 1. **Fix for this and nearly every later missing-dir blocker: run `systemd-tmpfiles --create` in prep** (one call makes the `/run/etc` dbus confs, `/run/fm` \[dfserver ipc\], `/run/dm/.ipc` \[datamgr\], …). Pinpointed by stracing `dbus-broker-launch` under `systemd-socket-activate` (SELinux permissive lets ptrace through): it died right after `openat(apphandler.conf)=ENOENT` with no `execve` of the broker at all.
2.  **dfserver** crashed at a `zloop_poller_end` assert — it binds `ipc:///var/run/fm/dfs_{client,control,notify,pub}.ipc` and `/run/fm` was absent (now made by tmpfiles).
3.  **Populators died instantly** (the "Stopping Populator …" churn): `dsm-sa-pop@.service` has `BindsTo=dsm-sa-datamgr.service` — when datamgr is launched *manually* the unit is inactive, so systemd kills every populator it spawns. **Run the mesh as systemd services, not by hand.**
4.  **cfgmgr stuck "activating"** (Type=notify, never sends `READY=1` — its dfserver func-provider attach handshake stalls under emulation) → blocked `dsm-sa-datamgr` (`After=`). cfgmgrd *does* run and own `com.dell.idrac.CfgMgr`, so a drop-in `Type=simple` + `WatchdogSec=0` marks it active → datamgr starts → 5 populators active → datamgr opens the SMIL pipes `/run/dm/.ipc/dcsmilpipe{a,p,u}` (racadm connects here; absent = **RAC1135** "instrumentation has stopped").
5.  **SWC0242 "Required License"**: the eMMC-persistence services (`early-mount`, `setup-flash`) the cascade pulls mount `/flash/data0` *read-only* over our tmpfs, so `lmcfg.txt` was unreadable. Neutralize them with a drop-in `ExecStart=/bin/true` (keeps dependents' ordering satisfied, no clobber) → `/flash` stays a writable tmpfs.
6.  **"current user privilege is not valid"**: local racadm reads its authenticated-user context from env that `racadmACShell` sets after SSH login. Reproduce it: `RACADM_ACCESS=0x1FF` (all 9 iDRAC privilege bits) + `USER`/`LC_USERNAME`/ `REMOTE_USERNAME=root`.

**Result — racadm is live:** it parses FQDDs and resolves object-model keys (`iDRAC.Users.2` → `iDRAC.Embedded.1#Users.2`; `Info.1`, `NIC.1`, `IPMILan.1`), enforces version policy (`getconfig` → `RAC1281` "use `racadm get`"), and returns proper RAC error codes — the full command pipeline (parse → auth → object model → instrumentation → cfgdb) works end-to-end.

**Still open:** (1) racadm returns no attribute *values* — `CfgCurrentValues.db` is a 12 KB skeleton (`cfgdbinit` seeds the 3.4 MB *metadata* schema, not factory values); needs the provider/populator data flow + a factory seed. (2) **RAKP / `fullfw`** (udp/623) — the "NPCM hardware shim" idea is **disproven**: qemu npcm750 models the msgbox (`c0008000`), KCS, LPC, PCI-mailbox and OTP — fullfw hits zero device errors. The real chain is software: fullfw blocks *"waiting for sensor shm"* → `sensord` must create the SDR shm, and sensord NULL-segfaulted on a missing per-platform `bmcsetting` file (staged from `/flash/pd0/ipmi/evb` in prep, like lmcfg). With that, sensord stays up (7 MB SDR shm), fullfw reads 350 SDR records + opens its function table + spawns its monitor thread — then SEGVs *post-init, only without strace* = a timing-dependent race in IPMI-channel setup. That race is the live RAKP blocker; `zipmi -K <915F32…>` still pending. **Dead-end:** full `multi-user.target` (`init.p5`/`init.p6`) — 182 services thrash without hardware (`usbmap` restart-looped 1753×) and never reach the target; the `mini.target` + targeted `systemctl start` is the correct path.

### Files map

- **Phase 1**: `run.sh`, `build.sh`, `init.custom`.
- **Phase 2**: `run-p2.sh`, `build-p2.sh`, `init.p2.custom`, `scripts/patch-kernel.py` (kernel NOP), `boot/p2.dts`/`p2uni.dts`.
- **Phase 3**: `run-p3.sh`, `ssh-in.sh`, `init.p3.custom`, `boot/p3.dts`, `img/vmkey` (VM keypair, git-ignored).
- **gdb**: `scripts/catch*.gdb` (dm_bufio), `scripts/ethcrash*.gdb` (the GMAC phylink crash). `boot/vmlinux.elf` = symbolized kernel (from kallsyms).

------------------------------------------------------------------------

*Historical sibling work used Unicorn emulation of `generateHashes` and a separate cold-start handoff; those source-tree records are not included in this repository. Written 2026-06-22.*
