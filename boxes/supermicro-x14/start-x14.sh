#!/usr/bin/env bash
#
# start-x14.sh — boot the virtual Supermicro X14 BMC (Phosphor OpenBMC / AST2600-ROT)
#
# WHAT:   Boots the X14SBSC BMC firmware under QEMU ast2600-evb, direct-kernel, to
#         full Supermicro OpenBMC userspace (systemd + bmcweb + ipmid + SMC daemons).
# WHY:    The vendor secure-boot chain (SMC SPL -> OP-TEE -> u-boot) can't complete
#         under QEMU (no TrustZone/OP-TEE/CPLD model). This skips it and boots the
#         vendor kernel+rootfs directly. Stage-1 "direct-kernel" approach; the full
#         ROT-chain boot is a separate research stretch.
# TARGET: BMC_X14AST2600-ROT-E601MS_20260306_01.01.06.07 (MBD-X14SBSC).
# NET:    10.0.8.14  (Dell iDRAC zbmc owns 10.0.9.x; X14 uses 10.0.8.x). Privileged
#         ports 22/443/623 need root -> qemu runs under sudo.
# STATUS: boots to `localhost login:` with all daemons. KNOWN GAP: guest eth0 gets
#         no IPv4 under qemu user-net (phosphor-network-manager vs ephemeral overlay),
#         so host->guest hostfwd to bmcweb/ipmid not yet reachable. See NEXT STEPS.
# RUN:    QEMU=/path/to/qemu-system-arm ./start-x14.sh   (reference launcher; Ctrl-A X to quit)
# DEPS:   qemu-system-arm (aspeed), the prepared artifacts below (built by PREP).
#
# ---- ARTIFACTS (in this dir; PREP shows how they were derived from the firmware) ----
#   x14-ce0-64m.img       first 64MB of the 128MB flash = active CE0 (u-boot+kernel+rofs)
#   kernel.bin x14.dtb    dumpimage -p0/-p1 of the FIT at flash 0x330000
#   initramfs-patched.bin  obmc-phosphor-initramfs (FIT -p2) + init patched to do a
#                          clean tmpfs RAM-overlay switch_root (token qemu-x14-ramroot)
#                          and drop a static eth0 (10.0.2.15) network config.
#   emmc.img              GPT eMMC (256MB): p9=rofs squashfs, p17=rwfs ext4, p8=env
#                          (init mounts rootfs from mmcblk0p9, NOT the NOR flash).
#
# ---- PREP (one-time; re-run if the firmware changes) ----
#   F=.../BMC_X14AST2600-ROT-E601MS_..._STDsp.bin
#   dd if=$F of=x14-ce0-64m.img bs=1m count=64                 # active image fits in 64MB
#   dd if=$F bs=4096 skip=$((0x330000/4096)) count=2560 of=k.bin
#   dumpimage -T flat_dt -p 0 -o kernel.bin k.bin             # kernel zImage
#   dumpimage -T flat_dt -p 1 -o x14.dtb    k.bin             # x14-ast2600-rot dtb
#   dumpimage -T flat_dt -p 2 -o initramfs.bin k.bin          # then patch init + repack (xz)
#   # emmc.img built by scratchpad/mkgpt.py + dd rootfs.sqsh into p9 + mke2fs p17
#
set -euo pipefail
cd "$(dirname "$0")"
IP="${ZBMC_IP:-10.0.8.14}"
QEMU="${QEMU:-$(command -v qemu-system-arm || true)}"
[ "$(uname -s)" = Linux ] || { echo "start-x14.sh supports Linux only" >&2; exit 1; }
[ -x "$QEMU" ] || { echo "set QEMU to an executable qemu-system-arm" >&2; exit 1; }

# ensure the loopback alias exists (idempotent)
ip addr show dev lo | grep -qw "$IP" || sudo ip addr add "$IP/32" dev lo
# free the port if a stale instance is around
sudo pkill -9 -f "hostname=x14bmc" 2>/dev/null || true; sleep 1

# The kernel-side fixes that make the vendor image boot under qemu ast2600-evb:
#   maxcpus=1                    ast2600-evb needs 2 CPUs but CPU1 bringup faults; cap in kernel
#   initcall_blacklist=...       skip ast2600_spitee_init + optee_driver_init (need secure world)
#   qemu-x14-ramroot             our initramfs bypass: tmpfs overlay switch_root (no eMMC rwfs mkfs)
#   systemd.mask=...             mask services that hang/fail on absent hw:
#     bmc-shared-lan-discovery   = NC-SI probe on sideband NICs -> THE cold-boot wedge
#     com.Supermicro.CPLDInit    = CPLD register init (no CPLD in qemu)
#     fan-boot-control           = set fan duty (no fans)
#     obmc-flash-bmc-setenv@     = u-boot env write (mtd env not writable here)
#   x14-noncsi.dtb               = eth1/eth2 (NC-SI macs) disabled -> nothing for NC-SI to probe
# Add DEBUG=1 env for verbose systemd logging (systemd.log_level=debug).
MASKS="systemd.mask=bmc-shared-lan-discovery.service systemd.mask=com.Supermicro.CPLDInit.service \
systemd.mask=fan-boot-control.service systemd.mask=obmc-flash-bmc-setenv@.service \
systemd.mask=sshdgenkeys.service systemd.mask=checkuid.service systemd.mask=clear-once.service"
LOG="loglevel=7"; [ "${DEBUG:-0}" = 1 ] && LOG="systemd.log_level=debug systemd.log_target=console loglevel=7"
APPEND="console=ttyS4,115200n8 root=/dev/ram rw maxcpus=1 \
initcall_blacklist=ast2600_spitee_init,optee_driver_init qemu-x14-ramroot $MASKS $LOG"

exec sudo "$QEMU" \
  -m 1024 -M ast2600-evb -nographic -no-reboot \
  -kernel kernel.bin -dtb x14-noncsi.dtb -initrd initramfs-patched.bin \
  -drive file=x14-ce0-64m.img,format=raw,if=mtd \
  -drive file=emmc.img,format=raw,if=sd,index=2 \
  -net nic -net user,hostfwd=tcp:$IP:${SSH_PORT:-22}-:22,hostfwd=tcp:$IP:${WEB_PORT:-443}-:443,hostfwd=udp:$IP:623-:623,hostname=x14bmc \
  -append "$APPEND"

# ---- NEXT STEPS (network last-mile) ----
# guest eth0 has no IPv4 -> hostfwd (host:$IP -> guest 10.0.2.15) has no listener.
# To finish: log in on the serial console (ADMIN/ADMIN) and inspect why
# phosphor-network-manager/systemd-networkd doesn't apply eth0 DHCP/static; likely
# needs a persisted network setting or masking phosphor-network-manager's eth0 mgmt.
# Once guest eth0 = 10.0.2.15, curl -k https://$IP/redfish/v1/ and
# ipmitool -I lanplus -H $IP -U ADMIN -P ADMIN ... should reach the live BMC.
