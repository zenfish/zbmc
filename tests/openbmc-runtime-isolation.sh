#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"

check_box(){
  local box="$1" machine="$2" output runtime firmware required qemu major actual_machine
  output=$(bash -c '
    _zbmc_resolve_ip(){ echo 127.0.0.1; }
    . "$1"
    printf "%s|%s|%s|%s|%s|%s\n" "$ZBMC_DIR" "$FIRMWARE_DIR" "$ZBMC_REQUIRED_SERVICES" "${ZBMC_QEMU:-}" "${ZBMC_QEMU_MAJOR:-}" "${ZBMC_QEMU_MACHINE:-}"
  ' bash "$repo/boxes/$box/zbmc.box")
  IFS='|' read -r runtime firmware required qemu major actual_machine <<<"$output"
  [ "$runtime" = "$repo/work/$box" ]
  [ "$firmware" = "$repo/firmware" ]
  [ "$runtime" != "$firmware" ]
  [[ " $required " == *' webui '* ]]
  if [ -n "$machine" ]; then
    [ "$qemu" = /home/zen/opt/qemu-11/bin/qemu-system-arm ]
    [ "$major" = 11 ]
    [ "$actual_machine" = "$machine" ]
  fi
}

check_box openbmc ast2600-evb
check_box nvidia-obmc gb200nvl-bmc
grep -Fq '_openbmc_retry_net_ipmi()' "$repo/boxes/openbmc/zbmc.box"
grep -Fq 'systemctl start phosphor-ipmi-net@eth0.socket' "$repo/boxes/openbmc/zbmc.box"
grep -Fq '"$ZBMC_QEMU" -M gb200nvl-bmc' "$repo/boxes/nvidia-obmc/zbmc.box"
grep -Fq 'PYTHONPATH="$ZIPMI" python3 -m zipmi.cli.zipmi' "$repo/boxes/nvidia-obmc/zbmc.box"
echo "OpenBMC runtime isolation and health contracts: PASS"
