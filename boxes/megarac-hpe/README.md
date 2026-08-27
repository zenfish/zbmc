<!-- html2md:auto source=boxes/megarac-hpe/README.html source-sha256=e6d3514776ff2748a24a4674aee5c126ebf6c52ae3b45071d5c9c8d963b8f96f body-sha256=ea7b95578c195885a090e2d676f4e086b18ec797cae851e9becedca790171cff -->

**Historical investigation record (2026-07-28).** Current release acceptance is ICMP plus retained IPMI. Redfish/Web-UI are unavailable, vendor SSH is absent, and the 2026-08-27 cold run took 8m07s after three automatic rerolls. Injected blank-password network shells are disabled unless requested. Use the repository README, SECURITY.md, and `zbmc megarac-hpe status -v` for current behavior.

# Virtual HPE Cray XD670 BMC

AMI **MegaRAC SP-X** (Linux 5.4.184-ami) on Aspeed **AST2600**, emulated with `qemu-system-arm -M ast2600-evb`.

Firmware: `XD670_BMC_v1.27_signed.bin.hpm` · zoo box `zbmc megarac-hpe` · 2026-07-28

## Why this box

The HPE Cray XD670 (a Gigabyte **G593** platform, 8× NVIDIA HGX H100/H200) does **not** run iLO. Its BMC is AMI MegaRAC SP-X — the same stack Eclypsium hit in [BMC&C Part 3](https://eclypsium.com/blog/ami-megarac-vulnerabilities-bmc-part-3/) with **CVE-2024-54085** (unauthenticated Redfish takeover via a crafted `X-Server-Addr` header). Eclypsium confirmed their work on the XD670 "+ Qemu" but published no emulation recipe; this box is that recipe, derived independently. First MegaRAC-on-Gigabyte entry in the zbmc zoo.

## Firmware anatomy (HPM → bootable pieces)

The `.hpm` is a PICMGFWU (HPM.1) wrapper around AMI **FMH** modules — **not** a linear flash image, so you can't just `dd` a flash and boot it. `extract.sh` carves:

| Piece | File offset | Notes |
|----|----|----|
| Kernel FIT (u-boot fitImage) | `0x37502CF` | Linux 5.4.184-ami, load 0x80001000; `dumpimage -p 0` for the raw Image |
| Rootfs (squashfs, xz) | `0x56028F` | 49.9 MiB; booted as a RAM disk (`root=/dev/ram0`) |
| /conf, /bkupconf (JFFS2) | `0x12028F`, `0x2C028F` | placed into a 64 MB NOR image with **named** mtd partitions |

## Boot recipe & gotchas

- qemu `-kernel` cannot unpack a FIT — extract the raw kernel `Image` first.
- Built-in `ram0` caps at 43008 KiB but the rootfs is 51108 KiB → must pass `ramdisk_size=131072`.
- Console is **ttyS4** (AST2600 UART5), matching the firmware's baked-in bootargs.
- Attaching the flash via `-drive if=mtd` needs it to be **exactly 64 MB** (FMC models a `w25q512jv`).
- `mountall.sh` finds `/conf` & `/bkupconf` by **name** in `/proc/mtd`, so the `mtdparts=` partition names must match. Empty conf partitions are auto-populated from `/etc/defconfig`.
- Console login: **sysadmin / superuser** (MegaRAC factory default; uid 0, restricted `defshell`). `init=/bin/sh` gives an unrestricted root shell.

## Status

Working

Full MegaRAC userland boots: real `/sbin/init`, `/conf` from JFFS2, config generated, eth0 gets DHCP, redis + event-service (luajit) + sync-agent + lighttpd + **IPMIMain** all up. Interactive console + root shell. **External Redfish ServiceRoot is reachable**: `curl -sk https://<ip>/redfish/v1/` → *AMI Redfish Server, Redfish 1.11.0*. The CVE-2024-54085 lua is present at `/usr/local/redfish/extensions/host-interface/host-interface-support-module.lua` (v1.27 is post-patch: the `X-Server-Addr` bypass is rejected).

The IPMIMain SIGSEGV fix (Ghidra RE)

`IPMIMain` used to SIGSEGV at startup, and after 15 crashes `procmgr` reboots the BMC (reboot loop). The reported PC `0x2c004` was a red herring — it's the signal handler; the real fault is `MsgHndlr` @`0x14864` in `libipmimsghndlr.so` dereferencing an **uninitialised field of the per-instance `g_BMCInfo[]` slot**. Two root causes, both emulation gaps:

- **Missing `/conf/BMC` symlink.** `IPMIMain` opens the literal path `/conf/BMC/IPMI.conf` to build the interface table; nothing creates the `/conf/BMC → BMC1/ast2600evb_ami` symlink under qemu. Fix: seed `/conf` from `/etc/defconfig` + create the symlink before first launch (in `etc/init.d/ipmistack`, sentinel-gated so it survives respawns).
- **Interfaces with no qemu hardware.** `MsgHndlr` spawns one thread per enabled interface and faults on those whose hardware qemu doesn't model — SERIAL (`ttyS2`) + SOL (`ttyS3`) (kernel only brings up `ttyS0/ttyS4`), plus IPMB/SMBUS/SMM. Fix: disable them in the seeded `IPMI.conf`; keep LAN, UDS, KCS1-3, BT.

Both are applied by `qemu-patch-rootfs.sh` (invoked from `extract.sh`) — no binary patching. Result: **boots stable — no SIGSEGV, no reboot loop** — and external Redfish ServiceRoot is reachable.

IPMI + auth now GREEN

Two more RE passes made IPMIMain run stably and provision its user, so **IPMI 2.0 RMCP+ and authenticated Redfish both work**:

- **Node-Manager self-stop.** `IPMIConf.c` refuses to run if `NM_IPMB_BUS` ∈ {0,1,2} points at a disabled IPMB bus. Set `NM_IPMB_BUS=0xFF` (≥3 = disable). Also disable **BT** — the central MsgHndlr thread faults on it too. qemu ast2600-evb backs only LAN + UDS + KCS.
- **Empty user table.** Once stable, IPMIMain auto-provisions the MegaRAC default IPMI user `admin` / `superuser` (Administrator, LAN channel 1) into `/conf/BMC1/UserConfig.ini`. Redfish shares that table via `pam_ipmi.so`. (My earlier failures used `sysadmin` — the Linux/console account — not the IPMI user.)

Verified: `ipmitool -I lanplus -U admin -P superuser mc info` → Gigabyte MfgID 15370, IPMI 2.0; `curl -u admin:superuser https://<ip>/redfish/v1/Managers` → real ManagerCollection JSON. SEGV=0, no reboot loop.

Reliable via warm snapshot (~4s restore)

IPMIMain hits a nondeterministic message-handler race on cold boot (central-MsgHndlr NULL-deref on an early client message; `maxcpus=1`/unloaded host don't remove it) — a good roll is fully green, a bad roll crash-loops. This paragraph records the historical snapshot-first experiment; current starts are cold by default and `zbmc megarac-hpe start --warm` is explicit.

**Address:** loopback `127.0.0.1` — IPMI `:5623`, Redfish `:5443`, ssh `:5022`. (Real-IP lo0-alias hostfwd serves Redfish/TCP fine, but qemu SLIRP mangles RMCP+'s multi-packet UDP on an alias, so IPMI-623 only stays reliable on loopback.) Verified: `ipmitool -I lanplus -H 127.0.0.1 -p 5623 -U admin -P superuser mc info` → Gigabyte MfgID 15370; `curl -sk -u admin:superuser https://127.0.0.1:5443/redfish/v1/Managers` → real JSON.

## Run it

    cd /Volumes/yyy/phd/bmc/HP/cray/xd670-virtual
    ./extract.sh                 # regenerate artifacts from the HPM (one-time)
    ./boot-cray.sh               # raw root shell (init=/bin/sh)
    ./boot-cray-svc.sh           # full init + networking (console login sysadmin/superuser)

    zbmc megarac-hpe console     # via the zoo dispatcher

HPE Cray XD670 BMC · MegaRAC SP-X v1.27 · AST2600 · qemu ast2600-evb · part of the zbmc zoo.
