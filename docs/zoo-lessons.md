# The BMC Zoo: Engineering Lessons for Running Vendor BMC Firmware Under QEMU

Cross-box patterns distilled from virtualizing nine BMCs across four vendors and three RTOS/Linux stacks
(Dell iDRAC9/10, Supermicro X14, HPE Cray XD670, Advantech ASMB-787, NVIDIA GB200NVL, vanilla OpenBMC,
Romulus, HPE iLO5). If you're trying to boot a vendor BMC image under an emulator, read this first — most
of these cost hours to learn the hard way.

Companion deep-dive on a single box end-to-end: [from-firmware-to-bare-metal.md](from-firmware-to-bare-metal.md).

## 1. Per-box table

| Box | Vendor / Stack | SoC + QEMU machine | Kernel | Boot method | Network last-mile | Console | Default creds | Working ifaces | #1 gotcha / lesson |
|---|---|---|---|---|---|---|---|---|---|
| **idrac9** | Dell iDRAC9 (custom Yocto + Dell mesh) | Nuvoton **NPCM750** (Poleg, ARMv7 dual A9); `qemu-system-arm -M npcm750-evb` | `5.4.80.idrac` (uImage) | direct-kernel `-kernel uImage.patched -dtb p4.dtb -initrd initramfs.p4.xz`; rootfs squashfs on **sd-bus** (`-device sd-card,bus=sd-bus`→mmcblk0); **cold** | **usb-net** (`-device usb-net,bus=usb-bus.0`) @10.0.2.15; on-chip GMAC/EMC link-up NULL-crashes kernel; hostfwd on real IP 10.0.9.9 | serial log file; ckpt boots add ttyS1 root shell | ssh: vmkey only (Dell PAM rejects pw); IPMI: factory IPMIKey `-K`; web: root:calvin | ssh, RAKP/IPMI, authed Redfish (all cold) | `CONFIG_CMDLINE_FORCE` — kernel **ignores `-append`**; only lever is `init=/init` in the initramfs you own |
| **idrac10** | Dell iDRAC10 (Yocto + Dell mesh) | Nuvoton **NPCM845** (aarch64); `qemu-system-aarch64 -M npcm845-evb` | `6.12.40` AArch64 (4 binary patches) | direct-kernel `-kernel Image.boot-patched -dtb qemu-gmac.dtb`; squashfs on sd-bus; **warm-restore snapshot** (~9s, self-healing ×3) | on-chip **npcm-gmac** (`model=npcm-gmac`) + slirp; **migrates clean** (unlike idrac9 usb-net); hostfwd 10.0.9.10 | `-serial unix:$SOCK` (16550 migrates fine) | ssh root (baked into ckpt); IPMI factory IPMIKey `-K`; web root:calvin | ssh, RAKP/IPMI, Redfish | cold boot = **dbus-broker socket-activate lottery** (~2/3 hang); fix = don't cold-boot — QMP `migrate` warm snapshot + frozen **qcow2 overlay** (NOT `snapshot=on`) |
| **x14** | Supermicro X14 (Phosphor **OpenBMC**, AST2600-ROT) | ASPEED **AST2600** (Cortex-A7); `qemu-system-arm -M ast2600-evb` | `5.15` zImage (FIT @flash 0x330000) | direct-kernel (FIT-carved); rootfs on **eMMC** (`-drive if=sd,index=2`→mmcblk0, GPT p9=rofs/p17=rwfs); **warm-restore** | slirp; **eth1/eth2 NC-SI disabled in dtb** (`x14-noncsi.dtb`); eth0 static 10.0.2.15; real IP 10.0.8.14 | `-serial unix:/tmp/x14.sock` + socat; QMP sock | ADMIN:ADMIN (IPMI+Redfish+ssh); root:0penBmc | Redfish (remote), ssh (real shell via `SMASH_ENABLE=0`), IPMI-LAN partial | cold init-system **spin-freezes under single TCG vCPU**; escape via **`qemu-x14-svc`** scripted daemon bring-up (no systemd) + snapshot |
| **cray** | HPE Cray XD670 = **AMI MegaRAC SP-X** | ASPEED **AST2600** (armv7l); `qemu-system-arm -M ast2600-evb` | `5.4.184-ami` (FIT kernel @0x37502CF) | direct-kernel; **rootfs squashfs as RAM disk** (`root=/dev/ram0 ramdisk_size=131072`); `/conf`+`/bkupconf` from 64MB NOR `-drive if=mtd`; warm snapshot | slirp DHCP → 10.0.2.15 (5.4.184 ftgmac negotiates qemu's NC-SI responder); **IPMI-623 only reliable on 127.0.0.1** (slirp mangles RMCP+ multi-UDP on alias) | ttyS4 getty; fifo `echo cmd > cin` | IPMI admin:superuser; console sysadmin:superuser | IPMI 2.0 RMCP+, authed Redfish | **IPMIMain SIGSEGV** = per-interface thread faults on hw-less ifcs; fix = seed `/conf/BMC→BMC1/ast2600evb_ami` symlink + disable serial/sol/bt/smm/smbus/ipmb + `NM_IPMB_BUS=0xFF` |
| **asmb787** | Advantech ASMB-787 = **AMI MegaRAC SP-X 4.0** | ASPEED **AST2600** (armv7l); `qemu-system-arm -M ast2600-evb` | `5.4.11-ami` | direct-kernel `-initrd rootfs.sqfs -drive if=mtd`; mtdparts match `/etc/dupfstab` mtdblock numbers; maxcpus=1 | **BLOCKED — NC-SI wall.** 5.4.11-ami ftgmac forces NC-SI + rejects qemu's responder (`packet type 0x82 returned -19`); usb-net hangs (AST2600 EHCI high-speed only) | ttyS4 via `zbmc asmb787 console '<cmd>'` fifo | sysadmin:superuser (console) | **console only** (all IP rides dead eth0) | NC-SI is **kernel-version-dependent**: cray's 5.4.184 works, asmb787's 5.4.11 doesn't — qemu handles NC-SI internally, no external "fake NIC" can help |
| **gb200** | NVIDIA GB200NVL (**OpenBMC**, NVIDIA OEM) | ASPEED **AST2600**; `qemu-system-arm -M gb200nvl-bmc` (custom machine) | bitbake `MACHINE=gb200nvl-obmc` | **flash-mtd** full image (`-drive if=mtd,snapshot=on`); cold | `-net nic -net user` slirp; real IP 10.0.7.20; net-ipmid comes up late | `-serial unix:$SOCK` (+`-serial null` for 2nd) | root:0penBmc | ssh, IPMI-LAN (**cipher-17 ONLY**), Redfish, OEM 0x3C via busctl | IPMI-LAN is **cipher-17 only** (`zipmi -C 17`); net-ipmid starts late so early probes look dead |
| **evb-openbmc** | **Vanilla upstream OpenBMC** (Phosphor) | ASPEED **AST2600**; `qemu-system-arm -M ast2600-evb` | Yocto `obmc-phosphor-image` | **flash-mtd** full `.static.mtd` (`-drive if=mtd,snapshot=on`); cold ~60-90s | `-net nic -net user` slirp; real IP 10.0.7.10 | serial0 = ttyS4 (`-serial unix:$SOCK`; **do NOT prepend `-serial null`**) | root:0penBmc | ssh, IPMI-LAN, Redfish (all green) | **Manufacturer ID 0 = the vanilla signature**; `-serial null` first sends console to /dev/null |
| **romulus** | Custom **multi-OEM OpenBMC** (OpenPOWER+Intel+Ampere+Facebook) | ASPEED AST2500; `qemu-system-arm -M romulus-bmc` | Phosphor `.static.mtd` | **flash-mtd**; loopback 2222/2443/2623 (`do-q`) | slirp, loopback high-ports | serial | (base OpenBMC) | ssh, Redfish, IPMI | base Get-Device-ID all-zero → looks vanilla; **check `/usr/lib/ipmid-providers/` not the device-id** — ipmid dlopens all 4 vendor OEM `.so` at once |
| **ilo5** | HPE iLO5 (**Green Hills INTEGRITY** RTOS, not Linux) | HPE **GXP** ASIC (Cortex-A9); **Renode** (not QEMU) | INTEGRITY 11.2.4 @0x41000000 | Renode `.repl` model; bl1→kernel; **gate-ledger binary patches** | n/a — no net yet | UART via modeled `gxp_sysctl@0xC0000000` | n/a (pre-app-load) | boots to healthy INTEGRITY idle | it's an **RTOS not Linux**: gates are scheduler/DDR-PHY/boot-handoff faults; **live-hook registers, don't over-theorize** |

## 2. Cross-cutting lessons

### QEMU machine selection per SoC
- **Nuvoton NPCM750** (iDRAC9, ARMv7 dual-A9) → `-M npcm750-evb` (`qemu-system-arm`). **NPCM845** (iDRAC10, aarch64) → `-M npcm845-evb` (`qemu-system-aarch64`). NPCM msgbox/KCS/LPC/PCI-mbox/OTP **are modeled**; genuinely absent: TPM, eMMC-RPMB secure store, PECI/I2C/ADC/PWM sensor data plane.
- **ASPEED AST2600** (x14, cray, asmb787, gb200, evb) → `-M ast2600-evb` (or a custom machine like `gb200nvl-bmc`). Cortex-A7. **AST2500** (romulus) → `-M romulus-bmc`.
- **HPE GXP** (iLO5, A9) has no QEMU machine — modeled from scratch in **Renode** (cribbed from zynq-7000: A9+GICv1+SCU+timers).

### Direct-kernel vs FIT (dumpimage) vs raw-flash boot
- **Full-flash (`-drive if=mtd,snapshot=on`)** is simplest, used by the *upstream/vendor OpenBMC* images that ship a bootable u-boot+kernel+rootfs in one blob: **evb, gb200, romulus**. `snapshot=on` keeps the built image pristine.
- **Direct-kernel** is required whenever the vendor SPL→u-boot→(OP-TEE/ROT) chain can't complete under emulation. Carve kernel/dtb/initrd from a **FIT** with `dumpimage -T flat_dt -p N`. `-kernel` **cannot unpack a FIT** — `dumpimage -p0` to a raw Image first. AST2600 ROT boxes wall at OP-TEE (no TrustZone/CPLD model) → skip to Linux with `initcall_blacklist=ast2600_spitee_init,optee_driver_init`.
- **iLO5** is neither: INTEGRITY loaded at a fixed link base (0x41000000) with a hand-written bl1 handoff and a gate-ledger of binary patches.

### Flash / MTD / rootfs sizing traps
- iDRAC9 rootfs must be a **block dev on the SDHCI sd-bus** (`if=none` + `-device sd-card,bus=sd-bus`→mmcblk0); generic `if=sd`/`-sd` is rejected. **SD size must be power-of-2**: pad 177MiB squashfs to 256MiB.
- iDRAC10: `nuvoton,npcm845-sdhci` @0xf0842000 must be in the minimal dtb or kernel panics "Cannot open root device".
- x14 rootfs is on **eMMC not NOR**: attach as `-drive if=sd,index=2` (index 0/1 = disabled sdhci slots); GPT partition **number must equal the entry index**.
- MegaRAC (cray/asmb787): NOR image must be **exactly 64MB** (FMC w25q512jv); `mtdparts=` names/offsets must match `mountall.sh`/`dupfstab` and each `@offset` must land on the real jffs2/squashfs magic. Rootfs squashfs runs as a **RAM disk** (`root=/dev/ram0 ramdisk_size=131072` — default ram0 too small).

### Console UART per SoC
- **NPCM750/845**: Dell console = `ttyS0` = `serial@1000` = first `-serial`. **Don't use `-nographic`** (steals serial-0 to stdio) — use `-display none -serial ...`.
- **AST2600**: console = **ttyS4**. On flash-mtd OpenBMC boxes `-serial unix:$SOCK` is serial0/ttyS4 — **do not prepend `-serial null`** (evb lesson: silent boot).
- **`CONFIG_CMDLINE_FORCE`** on both iDRAC kernels makes the compiled-in DTB bootargs override `-append` entirely. iDRAC10 needs 4 binary kernel patches (blank `quiet`, `loglevel=0`→`8`, inject `root=/dev/mmcblk0 ... init=/usr/bin/sh`). Shell is `/usr/bin/sh` NOT `/bin/sh` on iDRAC10.

### maxcpus / CPU bringup
- **AST2600-evb needs 2 CPUs but CPU1 bringup faults under TCG** → cap kernel-side with **`maxcpus=1`** (can't `-smp 1` — the machine wants 2). `-accel tcg,thread=multi` → guest won't boot (CPU1 faults).

### Cold-boot-flaky → warm-snapshot (QMP migrate) — the biggest reliability lever
Used on **idrac10, x14, cray**. Cold boot is nondeterministic under single-vCPU TCG (dbus-broker socket-activate lottery ~2/3 hang; init spin-freeze; IPMIMain race). Pattern:
- Cold-boot **retrying until a good box** (services up + IPMI answers), then QMP `stop` + `migrate exec:gzip` → `state.gz`.
- **Disk must stay consistent with migrated RAM**: use a **persistent qcow2 overlay**, NOT `snapshot=on` (iDRAC10: boot writes to /flash+/etc diverge on restore otherwise).
- Restore = `-incoming` + frozen overlay. iDRAC10 self-heals: **verify IPMI post-resume, re-restore up to 3×** (a migrated UDP socket sometimes resumes silent → port bound but guest never answers = timeout; fully-down = ECONNREFUSED).
- **What survives `-incoming` depends on the NIC**: NPCM845 gmac + x14-svc AST2600 restore with **live network**. iDRAC9 **usb-net does NOT re-enumerate** post-`-incoming` (EHCI async URBs don't resume) → warm restore network-dead, must cold-boot.
- x14 must **snapshot in `qemu-x14-svc` mode** — a normal-boot snapshot was network-dead.

### The network last-mile per SoC
- **NPCM**: on-chip GMAC (idrac10, clean) works; iDRAC9 GMAC/EMC link-up **NULL-crashes** so it falls back to **usb-net** (works but unmigratable). iDRAC9's usable NIC is the **EMC (eth2)** on old phylib, not GMAC.
- **AST2600 NC-SI wall** is kernel-version-dependent: qemu's ftgmac model **handles NC-SI internally** and never forwards 0x88F8 frames to the netdev. cray's **5.4.184-ami** negotiates with qemu's responder (link up, slirp DHCP). asmb787's **5.4.11-ami** driver forces NC-SI regardless of dtb and **rejects qemu's response** (`NCSI: Handler for packet type 0x82 returned -19`) → dead eth0. An external "fake NIC" responder is **impossible** (qemu intercepts NC-SI before any netdev). usb-net is not a fallback on AST2600 (EHCI is high-speed only → full-speed usb-net hangs).
- **OpenBMC noncsi dtb**: x14 disables the NC-SI sideband NICs eth1/eth2 in `x14-noncsi.dtb` (`status="disabled"`) + masks `bmc-shared-lan-discovery.service` (the oneshot that hangs probing absent NC-SI hw).
- **static-IP vs slirp DHCP**: emulated boxes usually get a static eth0 (10.0.2.15/24 gw 10.0.2.2) from the initramfs; flash-mtd OpenBMC images DHCP off slirp fine.
- **slirp mangles RMCP+ multi-packet UDP on a lo0 alias** (cray) → IPMI-623 only reliable on 127.0.0.1, even though Redfish TCP is fine on the alias.
- **IPMI_T timeout under emulation**: aarch64/armv7 RMCP+ RAKP is slow — iDRAC10 needs `IPMI_T=25`, cray `IPMI_T=20`. Short timeouts make a live box look dead.

### IPMIMain SIGSEGV fixes (MegaRAC)
- The PC in the crash (`0x2c004`) is the **SIGSEGV handler** — red herring. Real fault = `MsgHndlr` @0x14864 in `libipmimsghndlr.so` dereferencing an uninitialised `g_BMCInfo[]` slot. `devmap.xml` is orthogonal.
- Two real causes: (1) IPMIMain opens the **literal path** `/conf/BMC/IPMI.conf` — nothing creates the `/conf/BMC → BMC1/ast2600evb_ami` symlink under qemu → interface table never built; (2) `MsgHndlr` spawns one thread per enabled interface and faults on hw-less ones (serial/SOL on ttyS2/ttyS3 the kernel never brings up, IPMB/SMBUS/SMM).
- Fix (no binary patch, in `qemu-patch-rootfs.sh`): seed `/conf` from `/etc/defconfig`, create the `/conf/BMC` symlink before first launch, set `SUPPORT_{SERIAL,SOL,SMM,SMBUS}_IFC=0` + all `*_IPMB_SUPPORT=0` (keep LAN/UDS/KCS), and **`NM_IPMB_BUS=0xFF`** (the Node-Manager self-stop guard fires only for bus ∈ {0,1,2}). Ported clean from cray to asmb787.

### OpenBMC bmcweb / mapper fixes
- **bmcweb exits 255 on fresh boots** with no stderr: `main()` `inotify_add_watch(fd,"/var/log",...)` returns -1 → `exit_group(-1)`. `/var/log`→`/var/volatile/log` is a boot tmpfs made by systemd-tmpfiles; scripted (non-systemd) bring-up skips it. **Fix: `mkdir -p /var/volatile/log/redfish` before bmcweb.**
- bmcweb is **socket-activated** (`bmcweb.socket` ListenStream=443) — run via `systemd-socket-activate -l 0.0.0.0:443 /usr/bin/bmcweb`; bare exits 255.
- **Redfish is remote-usable, not loopback-usable** under emulation: `curl https://127.0.0.1/redfish` **hangs**, remote `curl https://IP/redfish` = 200. Endpoints touching `org.freedesktop.systemd1` crash without PID1 systemd; collections + ServiceRoot are stable.
- **mapperx empty-whitelist bug**: `needToIntrospect = inWhitelist && !inBlacklist` — an empty whitelist introspects **nothing** → empty object tree → ipmid wipes `ipmi_user.json` → RAKP "unauthorized name". **Fix: `mapperx --service-namespaces="$MAPPER_SERVICES"`** (from `/etc/default/obmc/mapper`).
- Meta-lesson (x14): daemons "dying mysteriously" across repeated runs = **suspect your own accumulated state first** — a stale `/var/run/dbus/pid` silently failed every dbus-daemon restart. Clear pidfiles/sockets before bring-up.

### RAKP / IPMI cipher quirks under emulation
- **gb200 is cipher-17 ONLY** (`zipmi -C 17 -I lanplus`); iDRAC9 also `-C 17`. OpenBMC in general is cipher-17-only.
- IPMI auth key is the **factory IPMIKey** via `-K` (first **20 bytes** / 40 hex — BMC RAKP key len hardcoded 20), NOT a password. iDRAC9/10 share it (unrotated).
- iDRAC10 RAKP gate findings: RAKP2 status `0x0d` = 16-byte username **MemCmp** miss (seed `UserName AttributeMemSize` = **16 not 4**, else "root"→"roo\0"); `0x0a` = priv nibble from raw entry byte `+0x25+channel`; HMAC key at entry`+0x11` (20B). RAKP1 username must be **NUL-padded to 16B** client-side.
- RAKP/RMCP reliability under single-vCPU TCG is a **QEMU/injection artifact, not a real-iDRAC property** — the warm-snapshot pattern is what makes it dependable.
- MegaRAC RAKP: `UserPassword` uses an `$ENCRYPTED$` sentinel → per-box AES-256-CBC blob (`UserEncPswd.ini`, key from `/conf/AESKey`+`AESIV`); plaintext-bypass if the field isn't the sentinel.

### Unpacking (FMH / SquashFS / JFFS2 / FIT)
- **Dell** (`tools/unpack-idrac`): auto-detects gen by firmimg extension (`.d9`=FIT via dumpimage, `.d10`=tar). DUP is a shell self-extractor (`7z x`→tar) or appended zip. **`unsquashfs -ignore-errors` is critical** for LZO rootfs on macOS — without it ~12k files silently become zero-length.
- **AMI MegaRAC** (`tools/unpack-ami`): FMH `$MODULE$` table, payload = header_offset + 0x10000. Traps: (1) **"encrypted_*.ima_enc" is a misnomer** — plain XZ-SquashFS (`hsqs` magic, size at superblock+0x28); (2) degraded **binwalk lacks the squashfs signature** and silently skips the rootfs — scan magics yourself; (3) **jefferson misdetects JFFS2 endianness** on the whole image (→0 nodes) — carve each region by node magic `85 19` (0x1985 LE) then run jefferson per-region; (4) macOS `dd` lacks `iflag=skip_bytes` — carve with `tail -c +N | head -c LEN`.
- HPM: cray firmware is a **PICMGFWU/HPM.1 wrapper** around AMI FMH modules, not linear flash — fixed-offset carve fails; use its extract.sh.

### The zbmc dispatcher pattern
Each box ships a `zbmc.box` descriptor (sourced by `tools/zbmc`) exposing uniform verbs: `zbmc_boot`
(restore warm snapshot if present, else cold; `ZBMC_COLD=1` forces cold), `zbmc_build`, `zbmc_snapshot`,
`zbmc_restore`, `zbmc_ssh`, `zbmc_ipmi`, `zbmc_ipmi_health`, `zbmc_web`, `zbmc_console`, plus
`ZBMC_READY_GREP` for a console readiness marker.
- **Root-direct model**: qemu runs as root (self-elevates via `sudo`) and binds the box's **real IP via a lo0 alias** + standard ports 22/443/623 directly — kills the socat/high-port indirection.
- **IP scheme**: 10.0.7.x = OpenBMC (evb/gb200), 10.0.8.x = Supermicro/MegaRAC (x14/cray/asmb787), 10.0.9.x = Dell (idrac9/10). Each zbmc binds a **specific** IP:22 so it coexists with the host's own sshd.
- qemu's real pid is found by the **hostfwd signature** (`pgrep -f "hostfwd=udp:$IP:623-:623"`), not `$!` (it's a root child of sudo).
- Access differs per stack and the descriptor encodes it: Dell/gb200 = IPMI `-K` factory key; x14/cray/evb = password. Health probes route around per-box quirks (x14 uses `channel info 1` because `mc info`=0xff; cray greps for the vendor MfgID).

---

*Distilled 2026-08 from a running research zoo. No extracted secret values are reproduced here — keys are
referred to by name (factory IPMIKey, CredVault AES key) and are, in any case, extractable from the
vendors' own publicly-downloadable firmware.*
