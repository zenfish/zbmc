#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
box="$repo/boxes/megarac-hpe"

grep -Fxq 'ZBMC_QEMU=/home/zen/opt/qemu-11/bin/qemu-system-arm' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MAJOR=11' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=ast2600-evb' "$box/zbmc.box"
for script in boot.sh boot-megarac-hpe.sh boot-megarac-hpe-svc.sh restore-megarac-hpe.sh; do
  grep -Fq 'QEMU_BIN="${ZBMC_QEMU:-${QEMU:-qemu-system-arm}}"' "$box/$script"
done
grep -Fq "IPMIMain is terminating because of SIGSEGV" "$box/start-megarac-hpe-green.sh"

echo "MegaRAC-HPE QEMU contract: PASS"
