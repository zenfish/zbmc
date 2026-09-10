#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
output=$(ZBMC_DIR="$tmp" ZBMC_SOURCE_ONLY=1 bash -c '
  _zbmc_resolve_ip(){ echo 127.0.0.1; }
  . "$1"
  printf "login: " > "$CONSOLE_LOG"
  . "$2"
  _probe_console
' bash "$repo/boxes/advantech-asmb787/zbmc.box" "$repo/tools/zbmc")
[[ "$output" == "ok|zbmc 127.0.0.1 console|serial login prompt observed" ]]
grep -Fq 'qemu/runtime/qemu-system-arm-debian' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MAJOR=10' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=ast2600-evb' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES=console' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fxq 'ZBMC_NETWORK_MODE=tap' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fxq 'ZBMC_TAP=ztap-asmb' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fxq 'ZBMC_MAC=52:54:00:fa:00:50' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fq 'TEMPORARILY BROKEN after clean rebuild' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fq 'Temporarily broken: regenerated guest has no serial/ARP/ICMP' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fxq 'ZBMC_DEFAULT_NO_WEB=1' "$repo/boxes/advantech-asmb787/zbmc.box"
! grep -q 'NC-SI responder' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fq "[ -p \"\$SOCK\" ] && printf '\\n' > \"\$SOCK\"" "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fq 'QEMU_BIN="${ZBMC_QEMU:-${QEMU:-qemu-system-arm}}"' "$repo/boxes/advantech-asmb787/boot.sh"
grep -Fq 'chgrp "${SUDO_GID:-$(id -g)}" cin; chmod 660 cin' "$repo/boxes/advantech-asmb787/boot.sh"
grep -Fq 'zbmc_asmb787_ip=$IP' "$repo/boxes/advantech-asmb787/boot.sh"
grep -Fq 'devmem 0x8098128c 32 0xe3a00000' "$repo/boxes/advantech-asmb787/direct-network.sh"
grep -Fq 'devmem 0x80981290 32 0xe12fff1e' "$repo/boxes/advantech-asmb787/direct-network.sh"
! grep -q 'hostfwd' "$repo/boxes/advantech-asmb787/boot.sh"

mkdir -p "$tmp/proc" "$tmp/conf" "$tmp/bin"
printf '%s\n' 'console=ttyS4 zbmc_asmb787_ip=10.250.0.50' > "$tmp/proc/cmdline"
printf '%s\n' 'Linux version 5.4.11-ami' > "$tmp/proc/version"
printf '#!/bin/sh\nprintf "%%s\\n" "$*" >> "$DEVMEM_LOG"\n' > "$tmp/bin/devmem"
chmod +x "$tmp/bin/devmem"
PATH="$tmp/bin:$PATH" DEVMEM_LOG="$tmp/devmem.log" ZBMC_PROC_ROOT="$tmp/proc" \
  ZBMC_CONF_ROOT="$tmp/conf" "$repo/boxes/advantech-asmb787/direct-network.sh" start >/dev/null
grep -Fxq '0x8098128c 32 0xe3a00000' "$tmp/devmem.log"
grep -Fxq '0x80981290 32 0xe12fff1e' "$tmp/devmem.log"
grep -Fxq '    address 10.250.0.50' "$tmp/conf/interfaces"
echo "Advantech console lifecycle: PASS"
