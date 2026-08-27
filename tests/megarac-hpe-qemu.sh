#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
box="$repo/boxes/megarac-hpe"

grep -Fq 'qemu/runtime/qemu-system-arm' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_SHA256=a066ffd52f50bc4555ea9af003e44e02aec3b3d260a37da8ab0b3d8c596790a6' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MAJOR=11' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=ast2600-evb' "$box/zbmc.box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES="ipmi"' "$box/zbmc.box"
grep -Fq 'partial: IPMI works; Redfish/Web-UI unstable; SSH absent' "$box/zbmc.box"
grep -Fq 'Never expose this guest outside an isolated lab' "$box/zbmc.box"
grep -Fq 'if [ -n "${ZBMC_WARM:-}" ]' "$box/zbmc.box"
for script in boot.sh boot-megarac-hpe.sh boot-megarac-hpe-svc.sh restore-megarac-hpe.sh; do
  grep -Fq 'QEMU_BIN="${ZBMC_QEMU:-${QEMU:-qemu-system-arm}}"' "$box/$script"
done
grep -Fq "IPMIMain is terminating because of SIGSEGV" "$box/start-megarac-hpe-green.sh"
grep -Fq 'python3 -m zipmi.cli.zipmi' "$box/start-megarac-hpe-green.sh"
grep -Fq 'redfish/v1/' "$box/start-megarac-hpe-green.sh"

echo "MegaRAC-HPE QEMU contract: PASS"
