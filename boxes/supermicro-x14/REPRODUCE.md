# Reproduce the virtual X14 BMC — firmware → working box

> **Historical reconstruction notes; not a complete current recipe.** The cited `x14.dts`, `mkgpt.py`,
> and patched init source are not in this repository. The supported build downloads hash-pinned derived
> artifacts with `./build.sh supermicro-x14`, then cold-starts with
> `sudo ./tools/zbmc supermicro-x14 start`. Current acceptance is SSH, IPMI, Redfish, and Web-UI.
> Preserve the steps below as investigation provenance, not a fresh-clone promise.

Clean-room rebuild of the Supermicro X14 virtual BMC (OpenBMC / AST2600) under QEMU, with
external SSH shell + IPMI + Redfish. Everything except the vendor firmware is in this repo;
the firmware `.bin` is proprietary (not redistributed) — you supply it.

## 0. Prereqs
- x86_64 Linux. Use the exact patched `qemu-system-arm` pinned in `zbmc.box`.
- `dumpimage` (u-boot-tools), `unsquashfs` (squashfs-tools), `mke2fs`, `xz`, `cpio`, `python3`.
- `ipmitool`, `sshpass`, `socat`, `curl` to drive it.

## 1. Get the firmware (you supply this)
Supermicro X14 BMC image, exact version this was built against:
```
BMC_X14AST2600-ROT-E601MS_20260306_01.01.06.07_STDsp.bin   (128 MB raw AST2600 flash)
```
From Supermicro's site (MBD-X14SBSC BMC firmware) or your own dump. Sanity:
```
xxd -l16 fw.bin | grep '1f00 00ea'       # ARM boot vector = raw AST2600 flash
strings -n8 fw.bin | grep arm-openbmc    # Phosphor OpenBMC marker
```

## 2. Carve kernel + dtb + initramfs (FIT @ flash 0x330000)
```
F=fw.bin
dd if=$F of=x14-ce0-64m.img bs=1m count=64                    # active CE0 image (u-boot+kernel+rofs)
dd if=$F bs=4096 skip=$((0x330000/4096)) count=2560 of=k.bin  # the FIT
dumpimage -T flat_dt -p 0 -o kernel.bin  k.bin               # kernel zImage
dumpimage -T flat_dt -p 1 -o x14.dtb     k.bin               # x14-ast2600-rot dtb
dumpimage -T flat_dt -p 2 -o initramfs.bin k.bin             # obmc-phosphor-initramfs
```
NC-SI wedge fix — build `x14-noncsi.dtb` from the committed decompiled source `x14.dts`:
disable the sideband NC-SI NICs so nothing hangs probing them, then recompile.
```
# in x14.dts, set status="disabled" on the eth1/eth2 nodes (1e690000 / 1e670000), then:
dtc -I dts -O dtb -o x14-noncsi.dtb x14.dts
```
(`x14.dts` is `dtc -I dtb -O dts` of the carved `x14.dtb`; it's in this repo, so the dtb is rebuildable.)

## 3. Extract the rootfs (squashfs @ flash 0x00D40000)
```
dd if=$F of=rootfs.sqsh bs=4096 skip=$((0x00D40000/4096)) count=$((55*1024*1024/4096))
unsquashfs -d rootfs rootfs.sqsh
```
(Full teardown + the SAA 252-command analysis: `bmc/supermicro/x14sbsc/teardown/extract.sh` + `X14-*-TEARDOWN.html`.)

## 4. Build the eMMC image (rootfs lives here, not the NOR flash)
Init mounts rootfs from `mmcblk0p9`. Build a 256 MB GPT: p9 = rofs squashfs, p17 = rwfs ext4, p8 = env.
```
python3 mkgpt.py emmc.img            # writes the GPT (both headers share one DISK_GUID)
dd if=rootfs.sqsh of=emmc.img seek=<p9-start> conv=notrunc
mke2fs -F -t ext4 ... emmc.img       # (p17 rwfs) — see mkgpt.py for the exact partition map
```

## 5. Patch the initramfs init → the SVC bringup + all fixes
The patched init (`initramfs-x/init`) adds three cmdline tokens and a scripted daemon bringup
(no systemd). Take the extracted initramfs, replace its `init` with this repo's `initramfs-x/init`,
repack:
```
cd initramfs-x && find . | sort | cpio -o -H newc -R 0:0 | xz --check=crc32 -c > ../initramfs-patched.bin
```
`--check=crc32` is mandatory (kernel xz decompressor). Tokens the init honors:
- `qemu-x14-ramroot` — tmpfs RAM-overlay switch_root (always).
- `qemu-x14-svc` — run `svc-bringup.sh` (the daemon stack) then drop to a root shell. **← use this.**
- `qemu-x14-shell` — exec /bin/sh as PID1 (manual bringup / debugging).

### The bringup fixes baked into init (each was RE'd — see SNAPSHOTS.md / memory)
1. **Redfish (bmcweb):** `mkdir -p /var/volatile/log/redfish` **before bmcweb** — bmcweb `main()`
   inotify-watches `/var/log`; missing dir ⇒ `exit(255)`.
2. **IPMI RAKP:** `mapperx --service-namespaces="$MAPPER_SERVICES"` (source `/etc/default/obmc/mapper`).
   Empty whitelist ⇒ mapper introspects nothing ⇒ ipmid wipes `ipmi_user.json` ⇒ RAKP "unauthorized name".
3. **SSH real shell:** `/etc/smash.conf` `SMASH_ENABLE=0` (vendor toggle: SMASH-CLP shell → `/bin/sh`)
   + `mkdir -p /dev/pts` **before** `mount -t devpts` (else no ptys → interactive ssh "PTY alloc failed")
   + `sshd -D -p 22`.

## 6. Cold boot
```
qemu-system-arm -m 1024 -M ast2600-evb -display none -no-reboot \
  -serial unix:/tmp/x14.sock,server,nowait -qmp unix:/tmp/x14-qmp.sock,server,nowait \
  -kernel kernel.bin -dtb x14-noncsi.dtb -initrd initramfs-patched.bin \
  -drive file=x14-ce0-64m.img,format=raw,if=mtd -drive file=emmc.img,format=raw,if=sd,index=2 \
  -net nic -net user,hostfwd=tcp:10.0.8.14:22-:22,hostfwd=tcp:10.0.8.14:443-:443,hostfwd=udp:10.0.8.14:623-:623 \
  -append "console=ttyS4,115200n8 root=/dev/ram rw maxcpus=1 \
           initcall_blacklist=ast2600_spitee_init,optee_driver_init qemu-x14-ramroot qemu-x14-svc loglevel=4"
```
(`maxcpus=1` — CPU1 bringup faults; `initcall_blacklist` skips the secure-world init that has no
TrustZone/OP-TEE/CPLD model under QEMU. `10.0.8.14` = a `lo0` alias.) `shell-x14.sh` wraps this.
Ready in ~60-70 s. This whole boot skips the vendor SMC secure SPL/OP-TEE chain (direct-kernel).

## 7. Snapshot once → restore in ~10 s forever after
```
./snapshot-x14.sh svc-snap-shell.gz     # QMP migrate exec:gzip (pauses the VM)
./restore-svc-x14.sh svc-snap-shell.gz  # qemu -incoming exec:gunzip — network survives (UDP+TCP)
```
Snapshots are gitignored (large binary) — you regenerate them; they are NOT needed to reproduce.

## 8. Verify (from the host)
```
ssh ADMIN@10.0.8.14                         # pw ADMIN -> real /bin/sh ; sudo -i (pw ADMIN) -> root
   #   serial console always: sudo socat - UNIX-CONNECT:/tmp/x14.sock  -> root PID1
ipmitool -I lanplus -H 10.0.8.14 -U ADMIN -P ADMIN user list 1   # ADMIN = ADMINISTRATOR
curl -sk -u ADMIN:ADMIN https://10.0.8.14/redfish/v1/Systems     # 200
```
Creds `ADMIN:ADMIN` + `root:0penBmc` were recovered from `/etc/ipmi_pass` with the fleet-static key
`OPENBMC=` — see `bmc/supermicro/x14sbsc/teardown/openbmc-ipmi-pass.py`.

## Once built, drive it from the framework
`./tools/zbmc supermicro-x14 start | status | ssh | ipmi <cmd> | web | snapshot`
