#!/usr/bin/env bash
# aten-boot.sh — generic direct-kernel boot for a Supermicro ATEN AST2600 BMC under zbmc.
#
# Boots the carved vendor kernel (SPL/OP-TEE bypass) with root directly from the NOR
# squashfs rofs partition, a blank GPT eMMC for /nv, and the box's real IP bound via a
# lo0 alias + qemu user-net hostfwd on the standard ports (623/443/80/22). This is the
# "vendor kernel, direct boot" recipe from lab/smc-x13/vm-boot.sh, generalized.
#
# Required env (exported by the box's zbmc.box zbmc_boot):
#   WD          work dir holding kernel.bin + fdt-patched.dtb (built by aten-build)
#   FLASH       the raw 64 MiB NOR firmware image (if=mtd, snapshot=on)
#   EMMC        blank GPT eMMC image (if=sd,index=2, snapshot=on); empty = omit
#   ZBMC_IP     real IP to bind (lo0 alias); hostfwd target
#   CONSOLE_SOCK  unix socket for the ttyS4 serial console (askfirst root shell)
#   LOG         qemu console log
# Optional env:
#   FMC_MODEL   SPI flash model (default mt25ql512ab = 512 Mbit / 64 MiB)
#   ROOT_MTD    root mtdblock index (default 0 = the injected rofs)
set -u
FMC_MODEL=${FMC_MODEL:-mt25ql512ab}
ROOT_MTD=${ROOT_MTD:-0}
APPEND="console=ttyS4,115200n8 earlycon=uart8250,mmio32,0x1e784000,115200n8 root=/dev/mtdblock${ROOT_MTD} rootfstype=squashfs ro rootdelay=1 irqchip.gicv2_force_probe=1 nosmp initcall_blacklist=ast2600_spitee_init loglevel=8"

cd "$WD" || exit 1
: > "$LOG"
DRIVES=(-drive file="$FLASH",format=raw,if=mtd,snapshot=on)
[ -n "${EMMC:-}" ] && DRIVES+=(-drive file="$EMMC",format=raw,if=sd,index=2,snapshot=on)
exec sudo -n qemu-system-arm -M "ast2600-evb,fmc-model=$FMC_MODEL" -m 1024 -display none \
  -kernel "$WD/kernel.bin" -dtb "$WD/fdt-patched.dtb" -append "$APPEND" \
  "${DRIVES[@]}" \
  -nic "user,hostfwd=udp:$ZBMC_IP:623-:623,hostfwd=tcp:$ZBMC_IP:443-:443,hostfwd=tcp:$ZBMC_IP:80-:80,hostfwd=tcp:$ZBMC_IP:22-:22,hostname=qemu" \
  -serial "unix:$CONSOLE_SOCK,server,nowait" -no-reboot >>"$LOG" 2>&1
