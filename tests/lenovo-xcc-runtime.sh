#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
box="$repo/boxes/lenovo-xcc"

bash -n "$box/build.sh"
bash -n "$box/boot.sh"
bash -n "$box/zbmc.box"
python3 -m py_compile "$box/build-shell-kernel.py"

grep -Fxq 'ZBMC_QEMU_MAJOR=11' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_SHA256=05de4c762687e826445b418c365e8da6dff051e6a2fe244ed0bbc161fa2e7e9f' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=ast2600-evb' "$box/zbmc.box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES="webui"' "$box/zbmc.box"
grep -Fxq 'ZBMC_DISABLED_SERVICES="ssh ipmi redfish"' "$box/zbmc.box"
grep -Fxq 'ZBMC_STABILITY_SECONDS=60' "$box/zbmc.box"
grep -Fxq 'ZBMC_READY_DEADLINE=3600' "$box/zbmc.box"
grep -Fxq "ZBMC_READY_GREP='XCC_RUNTIME_VPDOCTOR_BYPASS_BOUND'" "$box/zbmc.box"
grep -Fq 'kernel-shell.zImage' "$box/build.sh"
grep -Fq '4278396198eca68fb9e74d74d1f1339c2ba81dcbceec9a43a0d85eaf5d96eb0d' "$box/build.sh"
grep -Fq 'bd3335a465c8dc3d75e582135c433762b6ce1b0e6c32c7118f3a3cbe4eb1a0bc' "$box/build.sh"
! grep -Fq 'd228657d01262b741c72017764f8304570e1dbfb5c17145830842a248ed8c9d8' "$box/build.sh"
grep -Fq 'XCC_DIAG_SHELL_BOUND' "$box/build-shell-kernel.py"
grep -Fq 'mount --bind /xcc-diag-getty /rootfs/etc/scripts/rfs.getty' "$box/build-shell-kernel.py"
grep -Fq 'while [ ! -s /tmp/eth1_dhcpinfo ]; do sleep 1; done' "$box/build-shell-kernel.py"
grep -Fq $'ip addr replace 10.0.2.15/24 dev eth1 &&\nip route replace default via 10.0.2.2 dev eth1 &&\necho XCC_DIAG_NETWORK_READY' "$box/build-shell-kernel.py"

grep -Fq -- 'xcc-fpga=true,xcc-ptables-file=$WD/ptables.bin' "$box/boot.sh"
grep -Fq -- '-kernel "$WD/kernel-shell.zImage"' "$box/boot.sh"
grep -Fq -- '-global emmc.gp0-partition-size=3565158400' "$box/boot.sh"
grep -Fq -- 'if=sd,index=2,snapshot=on' "$box/boot.sh"
grep -Fq 'hostfwd=tcp:$IP:$HTTPS_PORT-:443' "$box/boot.sh"
grep -Fq 'hostfwd=tcp:$IP:$HTTP_PORT-:80' "$box/boot.sh"
grep -Fq 'hostfwd=udp:$IP:$IPMI_PORT-:623' "$box/boot.sh"
grep -Fq -- '-watchdog-action none' "$box/boot.sh"
grep -Eq '^lenovo-xcc[[:space:]]+10\.0\.6\.69$' "$repo/zhosts.txt"
grep -Fq 'lenovo-xcc-fpga-emmc-gp0.patch' "$repo/qemu/recipes/qemu-11-lenovo-xcc.sh"

(
  _zbmc_resolve_ip() { echo 127.0.0.1; }
  source "$box/zbmc.box"
  log=$(mktemp); called=$(mktemp); rm -f "$called"
  trap 'rm -f "$log" "$called"' EXIT
  ZBMC_CONSOLE_LOG="$log"
  curl() { : >"$called"; printf 200; }
  ! zbmc_webui_health >/dev/null
  [ ! -e "$called" ]
  printf '%s\n' '-> Web Available' >"$log"
  ! zbmc_webui_health >/dev/null
  [ ! -e "$called" ]
  printf '%s\n' 'XCC_DIAG_NETWORK_READY' >>"$log"
  zbmc_webui_health
  [ -e "$called" ]
)
