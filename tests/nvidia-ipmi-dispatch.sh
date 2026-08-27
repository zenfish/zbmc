#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
_zbmc_resolve_ip(){ echo 127.0.0.1; }
. "$repo/boxes/nvidia-obmc/zbmc.box"

_nvidia_ipmi_lan(){ printf 'lan:%s\n' "$*"; }
zbmc_ssh(){ printf 'ssh:%s\n' "$*"; }

[ "$(zbmc_ipmi mc info)" = 'lan:mc info' ]
[[ "$(zbmc_ipmi 0x3c 0x37 0x01)" == ssh:*'execute yyyaya{sv} 0x3c 0 0x37 1 0x01 0' ]]

echo 'NVIDIA IPMI command dispatch: PASS'
