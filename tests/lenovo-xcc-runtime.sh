#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
box="$repo/boxes/lenovo-xcc"

bash -n "$box/build.sh"
bash -n "$box/boot.sh"
bash -n "$box/zbmc.box"
python3 -m py_compile "$box/build-shell-kernel.py"

grep -Fxq 'ZBMC_QEMU_MAJOR=11' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_SHA256=0239888e57aeb1f73508f90eddd042f295988a275145a9717b0878cda041da69' "$box/zbmc.box"
grep -Fxq 'ZBMC_QEMU_MACHINE=ast2600-evb' "$box/zbmc.box"
grep -Fxq 'ZBMC_NETWORK_MODE=tap' "$box/zbmc.box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES="webui ipmi redfish"' "$box/zbmc.box"
grep -Fxq 'ZBMC_DISABLED_SERVICES="ssh"' "$box/zbmc.box"
grep -Fxq 'ZBMC_STABILITY_SECONDS=60' "$box/zbmc.box"
grep -Fxq 'ZBMC_READY_DEADLINE=3600' "$box/zbmc.box"
grep -Fq 'XCC_RUNTIME_VPDOCTOR_BYPASS_BOUND\|XCC_WARM_RESTORE_RUNNING' "$box/zbmc.box"
grep -Fq 'kernel-shell.zImage' "$box/build.sh"
grep -Fq '4278396198eca68fb9e74d74d1f1339c2ba81dcbceec9a43a0d85eaf5d96eb0d' "$box/build.sh"
grep -Fq 'bd3335a465c8dc3d75e582135c433762b6ce1b0e6c32c7118f3a3cbe4eb1a0bc' "$box/build.sh"
! grep -Fq 'd228657d01262b741c72017764f8304570e1dbfb5c17145830842a248ed8c9d8' "$box/build.sh"
grep -Fq 'XCC_DIAG_SHELL_BOUND' "$box/build-shell-kernel.py"
grep -Fq 'mount --bind /xcc-diag-getty /rootfs/etc/scripts/rfs.getty' "$box/build-shell-kernel.py"
grep -Fq 'while [ ! -s /tmp/eth1_dhcpinfo ]; do sleep 1; done' "$box/build-shell-kernel.py"
grep -Fq $'ip addr replace 10.0.2.15/24 dev eth1 &&\nip route replace default via 10.0.2.2 dev eth1 &&\necho XCC_DIAG_NETWORK_READY' "$box/build-shell-kernel.py"

grep -Fq -- 'xcc-fpga=true,xcc-ptables-file=$WD/ptables.bin' "$box/boot.sh"
grep -Fq -- '-kernel "$kernel"' "$box/boot.sh"
grep -Fq -- '-global emmc.gp0-partition-size=3565158400' "$box/boot.sh"
grep -Fq -- 'if=sd,index=2,snapshot=on' "$box/boot.sh"
grep -Fq 'tap,id=net0,ifname=$TAP,script=no,downscript=no' "$box/boot.sh"
grep -Fxq 'ZBMC_MAC=52:54:00:12:34:60' "$box/zbmc.box"
grep -Fq '_zbmc_network_prepare' "$repo/tools/zbmc"
grep -Fq 'python3 "$PROJ_DIR/configure-tap.py" "$SOCK" "$ZBMC_IP"' "$box/zbmc.box"
grep -Fq -- '-watchdog-action none' "$box/boot.sh"
grep -Eq '^lenovo-xcc[[:space:]]+10\.0\.6\.69$' "$repo/zhosts.txt"
grep -Fq 'lenovo-xcc-fpga-emmc-gp0.patch' "$repo/qemu/recipes/qemu-11-lenovo-xcc.sh"

# Readiness must require a successful authenticated read, not just matching text.
tmp=$(mktemp -d)
trap 'rm -f "$tmp/ipmitool"; rmdir "$tmp"' EXIT
cat > "$tmp/ipmitool" <<'STUB'
#!/usr/bin/env bash
[ "$IPMI_PASSWORD" = 'test-only-password' ] || exit 91
case " $* " in *' -E -C 17 -N 30 -R 1 mc info '*) ;; *) exit 92;; esac
case " $* " in *test-only-password*) exit 93;; esac
echo 'Manufacturer ID : 2'
exit "${TEST_IPMI_EXIT:-0}"
STUB
chmod +x "$tmp/ipmitool"
PATH="$tmp:$PATH"
_zbmc_resolve_ip() { echo 127.0.0.1; }
ZBMC_LENOVO_PASSWORD=test-only-password
. "$box/zbmc.box"
zbmc_ipmi_health >/dev/null
export TEST_IPMI_EXIT=1
if zbmc_ipmi_health >/dev/null; then
  echo 'failed command incorrectly passed IPMI readiness' >&2
  exit 1
fi

(
  curl() { printf '{"UserName":"USERID","Enabled":true}'; }
  zbmc_redfish_health | grep -Fq 'AUTH OK (protected Redfish account read)'
  curl() { printf '{"UserName":"someone-else","Enabled":true}'; }
  ! zbmc_redfish_health >/dev/null
)

python3 "$repo/tests/lenovo-xcc-boot-config.py"
python3 "$repo/tests/lenovo-xcc-tap-config.py"

(
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

python3 "$repo/tests/lenovo-xcc-restore.py"
(
  log=$(mktemp)
  trap 'rm -f "$log"' EXIT
  LOG="$log"
  ZBMC_CONSOLE_LOG=/nonexistent/cold-console
  printf '%s\n' XCC_WARM_RESTORE_RUNNING >"$LOG"
  curl() { printf 200; }
  zbmc_webui_health
  curl() { printf 503; }
  ! zbmc_webui_health >/dev/null
)
