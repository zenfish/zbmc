<!-- html2md:auto source=boxes/megarac-hpe/EMULATION-STATUS.html source-sha256=41c63988c21da4f5763b0254ee3f73943df850041a57ac539b36754e49c17257 body-sha256=34bd398e5c7d377cb54790415cda8d9a667289e8c5c37943323afd9ea9685e22 -->

**Historical status snapshot (2026-08-21).** It records one investigation state, not the current release contract. Current acceptance is ICMP plus retained IPMI; consult the repository README, SECURITY.md, and `zbmc megarac-hpe status -v`.

zbmc · megarac-hpe

# Emulation Status: HPE Cray XD670 BMC

AMI MegaRAC SP-X 13.04 · AST2600 (Cortex-A7) · qemu ast2600-evb · Last updated 2026-08-21

## At a Glance

| Subsystem | Status | Notes |
|----|----|----|
| Linux boot | works | Full `/sbin/init`, `/conf` from JFFS2, all daemons start. Console on ttyS4. |
| SSH (dropbear) | works | Port 22. `sysadmin` / blank pw → uid=0 root shell. Static musl soft-float ARMv5T binary. |
| Telnet (mini_telnetd) | works | Port 23. No auth, direct `/bin/sh`, uid=0. Static ARMv4T binary. |
| IPMI 2.0 RMCP+ | works | UDP 623. `admin`/`superuser`. Gigabyte MfgID 15370. `mc info`, `user list`, `channel info` all verified. |
| Redis | works | Unix socket `/run/redis/redis.sock`. ~1032 keys. Full Redfish data model populated. |
| Redfish service root | works | `/redfish/v1/` returns 200 (no auth required per spec). AMI Redfish Server, v1.11.0. |
| Redfish protected endpoints | broken | `/Managers`, `/Systems`, `/AccountService`, `/Chassis` all return `AccessDenied` or `ServiceInUnknownState` — even with valid credentials. Backend providers never fully initialize. |
| IPMIMain stability | flaky | Cold boot: SEGV race in central MsgHndlr. Warm snapshot sidesteps it but services still die within minutes. Guest eventually watchdog-reboots. |
| Warm snapshot | works | QMP snapshot → `cray-snap.gz` (~166 MB). Restores in ~10s. Always use this, never cold boot. |
| Filesystem access | works | Full rootfs extracted to `work/unpacked/`. All Lua, configs, binaries accessible for static RE. |
| NC-SI / host NIC | n/a | qemu ast2600 ftgmac100 has no NC-SI peer. Known wall across all ast2600 zoo boxes. |

## Architecture

    ┌─────────────────────────────────────────────────────────────────┐
    │  macOS Host                                                     │
    │                                                                 │
    │  sudo qemu-system-arm -M ast2600-evb -m 1024                   │
    │    -kernel kernel.Image  -dtb dtb-a1.dtb  -initrd rootfs.sqfs  │
    │    -drive mtdflash.bin (64MB NOR)                               │
    │    -net user,hostfwd=...                                        │
    │                                                                 │
    │  SLIRP hostfwd:                                                 │
    │    10.0.6.66:443  → guest:443  (Redfish/HTTPS)                  │
    │    10.0.6.66:22   → guest:22   (dropbear SSH)                   │
    │    10.0.6.66:23   → guest:23   (mini_telnetd)                   │
    │    10.0.6.66:623  → guest:623  (IPMI RMCP+ UDP)                 │
    │    10.0.6.66:5123 → guest:5123 (Intel ASD)                      │
    │                                                                 │
    │  10.0.6.66 = lo0 alias (sudo ifconfig lo0 alias 10.0.6.66)     │
    └─────────────────────────────────────────────────────────────────┘
                                  │
    ┌─────────────────────────────┴───────────────────────────────────┐
    │  Guest: Linux 5.4.184-ami (armv7l, Cortex-A7)                   │
    │                                                                 │
    │  rootfs.sqfs (read-only squashfs, booted as RAM disk)           │
    │  /conf, /bkupconf → mtdflash.bin JFFS2 partitions (writable)   │
    │                                                                 │
    │  Services:                                                      │
    │    IPMIMain        → IPMI stack (LAN, UDS)         ⚠ unstable  │
    │    lighttpd        → HTTPS :443                    ✓            │
    │    luajit (turbo)  → Redfish Lua handlers          ✓ front-end  │
    │    redis-server    → /run/redis/redis.sock         ✓            │
    │    sync-agent      → host-interface sync           ✓            │
    │    dropbear        → SSH :22 (injected)            ✓            │
    │    mini_telnetd    → telnet :23 (injected)         ✓            │
    │    procmgr         → watchdog/restart supervisor   ✓ (too well) │
    │    usb0            → host-interface NIC            ✓ (no peer)  │
    └─────────────────────────────────────────────────────────────────┘

## What Works in Detail

### Shell Access (SSH + Telnet)

**SSH (port 22):** Custom-built static dropbear 2024.86 (musl soft-float ARMv5T, 317K). Injected into rootfs by `qemu-patch-rootfs.sh` at `/usr/local/bin/dropbear`. Launched from `ipmistack` init script after IPMIMain. Blank password for `sysadmin` (`dropbear -B`). Host keys auto-generated in `/var/dropbear/` via `/etc/dropbear → /var/dropbear` symlink baked into squashfs.

**Telnet (port 23):** Static `mini_telnetd` (ARMv4T, ~10K). No authentication, direct `/bin/sh`, uid=0. Good for scripted commands when SSH hangs (snapshot stale connections).

**Hard-float gotcha:** qemu ast2600-evb emulates Cortex-A7 without VFP/NEON (`/proc/cpuinfo` shows no vfp features). Hard-float binaries SIGILL immediately. All injected binaries must be soft-float. The failed `dropbear-vfp-bad` (302K, Flags 0x5000400) is kept in `prebuilt/` as a reference.

### IPMI 2.0 RMCP+

IPMIMain binds LAN on UDP 623. Standard RMCP+ authentication works — `admin`/`superuser` (auto-provisioned MegaRAC default, user slot 2, Administrator privilege). Verified commands: `mc info` (Gigabyte MfgID 15370), `user list`, `channel info`, `chassis status`. Slow (~15-20s for RAKP under emulation, set `IPMI_T=20`).

### Redis

redis-server listens on Unix socket `/run/redis/redis.sock` (not TCP 6379). ~1032 keys populated after a successful boot. Full Redfish data model: Managers, Systems, Chassis, HostInterfaces, EthernetInterfaces, AccountService, all with realistic values. Access: `redis-cli -s /run/redis/redis.sock KEYS "*"`

### Warm Snapshot

QMP `savevm` captures a green state to `cray-snap.gz` (~166 MB) + `cray-snap-flash.bin` (64 MB NOR copy). Restore via `-incoming exec:gunzip` brings the VM back to a working state in ~10 seconds. Always use this — cold boot is unreliable. Scripts: `snapshot-megarac-hpe.sh` (capture), `restore-megarac-hpe.sh` (restore). `zbmc megarac-hpe start` auto-detects and uses the snapshot.

### Static RE (Filesystem)

Full rootfs extracted at `work/unpacked/fw-filesystems/rootfs/`. All Lua bytecode, C libraries, init scripts, redis init scripts (`.rcmd`), configs accessible. Sufficient for: CVE analysis, binary RE (Ghidra), protocol analysis, credential extraction. Does not require a running VM.

## What Doesn't Work

### Redfish Protected Endpoints

The Redfish Lua front-end (Turbo web framework) works — it serves the service root at `/redfish/v1/` and runs the host-interface authentication logic. But every protected endpoint (`/Managers`, `/Systems`, `/AccountService`, `/Chassis`, `/SessionService`) returns one of two errors:

- `Base.1.12.ServiceInUnknownState` — backend providers not initialized
- `Security.1.0.AccessDenied` — backend denies the connection

These errors appear **even with valid credentials** (`admin:superuser`). The issue is the backend service providers (C binaries that translate IPMI data into Redfish JSON) depend on IPMIMain being fully stable, which it isn't. The Lua layer authenticates correctly but has nothing to proxy to.

### IPMIMain Stability

IPMIMain has two failure modes, both from missing QEMU hardware:

1.  **Cold-boot crash race** — central MsgHndlr thread NULL-derefs on an early client message before initialization completes. Nondeterministic: depends on thread scheduling. A good roll boots green; a bad roll SIGSEGV-loops. After 15 crashes, `procmgr` reboots the guest. Cold boot success rate: ~20-30%. `start-megarac-hpe-green.sh` retries up to 6 times.
2.  **Post-boot degradation** — even after a successful boot (or warm restore), background threads periodically hit interfaces that don't exist in QEMU (IPMB polling, sensor scanning, SMBUS probes). These accumulate until `procmgr`'s health watchdog kills IPMIMain, which cascades to a guest reboot. Typical survival time: 2-15 minutes.

**Mitigation applied:** `qemu-patch-rootfs.sh` disables all IPMI interfaces without backing QEMU hardware (KCS1-3, SERIAL, SOL, BT, SMM, SMBUS, IPMB) and sets `NM_IPMB_BUS=0xFF` (Node-Manager guard). This fixed the immediate startup crash but doesn't prevent all background faults.

### NC-SI / Host NIC

qemu's ast2600-evb `ftgmac100` NICs have no NC-SI peer implementation. The "has no peer" warnings at boot are cosmetic, but the host-BMC sideband channel (NC-SI over the shared NIC) cannot be tested. This is a known wall across all AST2600 zoo boxes (x14, asmb787, evb).

## Rootfs Patches

`qemu-patch-rootfs.sh` applies 6 fixes to the squashfs before repacking. All are squashfs-level (no binary patching). Applied automatically by `extract.sh`.

| Fix | What | Why |
|----|----|----|
| 1 | Create `/conf/BMC → BMC1/ast2600evb_ami` symlink | IPMIMain reads literal `/conf/BMC/IPMI.conf` |
| 2 | Seed `IPMI.conf`: disable KCS/SERIAL/SOL/BT/SMM/SMBUS/IPMB, `NM_IPMB_BUS=0xFF` | MsgHndlr threads crash on absent hardware |
| 3 | `/usr/local/bin/smash → /bin/sh` | Console admin login shell |
| 4 | Deploy dropbear + telnetd to `/usr/local/bin/`; `/etc/dropbear → /var/dropbear` symlink | Shell access (squashfs is read-only; host keys need writable dir) |
| 5 | Inject dropbear/telnetd launcher into `ipmistack` init script | Start SSH+telnet after IPMIMain (survives procmgr restarts) |
| 6 | Patch `S07conf-seed.sh`: change sysadmin shell to `/bin/sh`, clear shadow password, create `/var/tmp/rc-init-complete` early | Allow blank-pw SSH; prevent 360s UDS gate delay |

## Files

| File | Purpose |
|----|----|
| extract.sh | Carve HPM → bootable artifacts + patch rootfs |
| qemu-patch-rootfs.sh | Apply all 6 rootfs fixes (called by extract.sh) |
| boot-megarac-hpe.sh | Raw shell boot (init=/bin/sh, no network) |
| boot-megarac-hpe-svc.sh | Full service boot (real init + SLIRP networking) |
| start-megarac-hpe-green.sh | Health-gated cold boot (retries until green) |
| snapshot-megarac-hpe.sh | Capture QMP warm snapshot from green boot |
| restore-megarac-hpe.sh | Restore from warm snapshot (~10s to green) |
| zbmc.box | Zoo box descriptor (zbmc megarac-hpe \<verb\>) |
| prebuilt/dropbear | Static musl soft-float ARMv5T SSH server (317K) |
| prebuilt/telnetd | Static ARMv4T mini_telnetd (~10K) |
| IPMI.html | IPMI protocol analysis notes |

## Access Quick Reference

    # Start (warm snapshot, ~10s)
    zbmc megarac-hpe start

    # SSH (root shell)
    zbmc megarac-hpe ssh           # or: sshpass -p '' ssh sysadmin@10.0.6.66

    # Telnet (root shell, no auth)
    nc 10.0.6.66 23

    # IPMI
    zbmc megarac-hpe ipmi mc info  # or: zipmi -H 10.0.6.66 -U admin -P superuser mc info

    # Redfish (service root only — protected endpoints broken)
    curl -sk https://10.0.6.66/redfish/v1/

    # Redis (via SSH)
    zbmc megarac-hpe ssh 'redis-cli -s /run/redis/redis.sock KEYS "*HostInterface*"'

    # Console (serial ttyS4)
    zbmc megarac-hpe console

    # RE shell (init=/bin/sh, no network, separate qemu)
    zbmc megarac-hpe shell

## Known Issues & Future Work

- **IPMIMain post-boot death.** Background threads still probe absent hardware. Could be fixed by deeper IPMI.conf surgery (disable all sensor scanning, IPMB polling) or by binary-patching `libipmimsghndlr.so` to NOP the offending thread spawns. The warm snapshot buys time but doesn't prevent the eventual crash.
- **Redfish backend providers.** These are C binaries (`/usr/local/redfish/oem/`) that bridge IPMI data to Redfish JSON. They depend on IPMIMain being fully healthy, which it isn't. Until IPMIMain is stabilized, Redfish API testing (including CVE-2024-54085 end-to-end demo) requires real hardware.
- **Port 22 collision.** Mac's own sshd binds `*:22`, which answers on the lo0 alias IP (10.0.6.66:22) when QEMU's guest sshd is down. Can look like SSH is up when it's actually the host. Banner check: BMC = `SSH-2.0-dropbear_2024.86`; Mac = `SSH-2.0-OpenSSH_10.2`.
- **NC-SI.** Requires qemu ftgmac100 NC-SI peer implementation. Shared wall across all AST2600 zoo boxes.
- **Snapshot staleness.** Snapshot was built against a specific rootfs.sqfs. If you re-run `extract.sh` (re-patching rootfs), the old snapshot boots the old rootfs from its embedded RAM disk. Rebuild with `zbmc megarac-hpe snapshot` after any rootfs change.

HPE Cray XD670 BMC · AMI MegaRAC SP-X 13.04 · XD670_BMC_v1.27_signed.bin.hpm · qemu ast2600-evb · zbmc zoo box `megarac-hpe`
