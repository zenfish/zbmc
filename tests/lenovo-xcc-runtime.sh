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
grep -Fxq 'ZBMC_REQUIRED_SERVICES="webui ipmi"' "$box/zbmc.box"
grep -Fxq 'ZBMC_DISABLED_SERVICES="ssh redfish"' "$box/zbmc.box"
grep -Fxq 'ZBMC_STABILITY_SECONDS=60' "$box/zbmc.box"
grep -Fxq 'ZBMC_READY_DEADLINE=3600' "$box/zbmc.box"
grep -Fxq "ZBMC_READY_GREP='XCC_RUNTIME_VPDOCTOR_BYPASS_BOUND'" "$box/zbmc.box"
grep -Fq 'kernel-shell.zImage' "$box/build.sh"
grep -Fq '1984706eedb75b76f0ceccac4f57f46c2b2f0c2b47b1bde256d2c0f609ea8c13' "$box/build.sh"
grep -Fq 'XCC_DIAG_SHELL_BOUND' "$box/build-shell-kernel.py"
grep -Fq 'mount --bind /xcc-diag-getty /rootfs/etc/scripts/rfs.getty' "$box/build-shell-kernel.py"

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
