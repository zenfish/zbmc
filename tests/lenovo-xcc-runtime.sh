#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
box="$repo/boxes/lenovo-xcc"

bash -n "$box/build.sh"
bash -n "$box/boot.sh"
bash -n "$box/zbmc.box"

grep -Fxq 'ZBMC_QEMU_MAJOR=11' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_SHA256=05de4c762687e826445b418c365e8da6dff051e6a2fe244ed0bbc161fa2e7e9f' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=ast2600-evb' "$box/zbmc.box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES="webui"' "$box/zbmc.box"
grep -Fxq 'ZBMC_DISABLED_SERVICES="ssh ipmi redfish"' "$box/zbmc.box"
grep -Fxq 'ZBMC_STABILITY_SECONDS=60' "$box/zbmc.box"
grep -Fxq 'ZBMC_READY_DEADLINE=900' "$box/zbmc.box"
grep -Fxq "ZBMC_READY_GREP='XCC_RUNTIME_VPDOCTOR_BYPASS_BOUND'" "$box/zbmc.box"

grep -Fq -- 'xcc-fpga=true,xcc-ptables-file=$WD/ptables.bin' "$box/boot.sh"
grep -Fq -- '-global emmc.gp0-partition-size=3565158400' "$box/boot.sh"
grep -Fq -- 'if=sd,index=2,snapshot=on' "$box/boot.sh"
grep -Fq 'hostfwd=tcp:$IP:$HTTPS_PORT-:443' "$box/boot.sh"
! grep -Fq 'hostfwd=tcp:$IP:$HTTP_PORT-:80' "$box/boot.sh"
grep -Fq 'hostfwd=udp:$IP:$IPMI_PORT-:623' "$box/boot.sh"
grep -Eq '^lenovo-xcc[[:space:]]+10\.0\.6\.69$' "$repo/zhosts.txt"
grep -Fq 'lenovo-xcc-fpga-emmc-gp0.patch' "$repo/qemu/recipes/qemu-11-lenovo-xcc.sh"
