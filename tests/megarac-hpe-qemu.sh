#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
box="$repo/boxes/megarac-hpe"

grep -Fxq 'ZBMC_QEMU=/home/zen/opt/zbmc-qemu/qemu-11.0.0-98b060da-arm-ftgmac-dynamic-48da50c30ab4/bin/qemu-system-arm' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_SHA256=ed299dae28d00252854335939380a1d9410f284fc3b918833fc783e5e6ca682c' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MAJOR=11' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=ast2600-evb' "$box/zbmc.box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES="ssh ipmi redfish webui"' "$box/zbmc.box"
for script in boot.sh boot-megarac-hpe.sh boot-megarac-hpe-svc.sh restore-megarac-hpe.sh; do
  grep -Fq 'QEMU_BIN="${ZBMC_QEMU:-${QEMU:-qemu-system-arm}}"' "$box/$script"
done
grep -Fq "IPMIMain is terminating because of SIGSEGV" "$box/start-megarac-hpe-green.sh"
grep -Fq 'python3 -m zipmi.cli.zipmi' "$box/start-megarac-hpe-green.sh"
grep -Fq 'redfish/v1/' "$box/start-megarac-hpe-green.sh"

echo "MegaRAC-HPE QEMU contract: PASS"
