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
grep -Fxq 'ZBMC_QEMU=/usr/bin/qemu-system-arm' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MAJOR=10' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=ast2600-evb' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES=console' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fxq 'ZBMC_L2_REQUIRED=0' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fxq 'ZBMC_DEFAULT_NO_WEB=1' "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fq "[ -p \"\$SOCK\" ] && printf '\\n' > \"\$SOCK\"" "$repo/boxes/advantech-asmb787/zbmc.box"
grep -Fq 'QEMU_BIN="${ZBMC_QEMU:-${QEMU:-qemu-system-arm}}"' "$repo/boxes/advantech-asmb787/boot.sh"
echo "Advantech console lifecycle: PASS"
