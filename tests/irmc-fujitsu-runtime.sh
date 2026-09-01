#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
box="$repo/boxes/irmc-fujitsu"

bash -n "$box/build.sh"
bash -n "$box/boot.sh"
bash -n "$box/zbmc.box"

grep -Fxq 'ZBMC_QEMU_MAJOR=11' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=ast2600-evb' "$box/zbmc.box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES="webui"' "$box/zbmc.box"
grep -Fxq 'ZBMC_DISABLED_SERVICES="redfish"' "$box/zbmc.box"
grep -Fxq 'ZBMC_READY_DEADLINE=900' "$box/zbmc.box"
grep -Fxq "ZBMC_READY_GREP='INIT: Entering runlevel: 3'" "$box/zbmc.box"
grep -Fq 'source_flash_sha256=89dd885694ebc86af29e900f04e22d4b63998ac35055e18c86ba96d6016ce2ed' "$box/build.sh"

grep -Fq -- '-nic user -nic user' "$box/boot.sh"
grep -Fq -- '-nic "user,net=192.168.2.0/24' "$box/boot.sh"
grep -Fq 'hostfwd=udp:$IP:$IPMI_PORT-:623' "$box/boot.sh"
grep -Fq 'hostfwd=tcp:$IP:$HTTPS_PORT-:443' "$box/boot.sh"
grep -Fq 'irmc_no_redfish' "$box/boot.sh"
grep -Fq 'RMCP+ IPMI starts but does not answer' "$box/index.html"
grep -Eq '^irmc-fujitsu[[:space:]]+10\.0\.6\.68$' "$repo/zhosts.txt"
grep -Fq 'irmc-fujitsu' "$repo/qemu/recipes/qemu-11-arm.sh"
