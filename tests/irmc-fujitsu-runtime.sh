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
grep -Fq 'initramfs-shell.cpio.gz' "$box/boot.sh"
grep -Fq 'irmc_diag_shell' "$box/boot.sh"
grep -Fq 'irmc_diag_root' "$box/boot.sh"
grep -Fq '/newroot/usr/local/bin/remman' "$box/build.sh"
grep -Fq "busybox echo 'exec /bin/sh -i'" "$box/build.sh"
grep -Fq 'getty -n -l /usr/local/bin/remman' "$box/build.sh"

tmp=$(mktemp -d)
trap 'rm -f "$tmp/socat"; rmdir "$tmp"' EXIT
cat >"$tmp/socat" <<'EOF'
#!/usr/bin/env bash
printf 'prompt: ###(ESPI):haGetEspiPCHRTC(RX) : ERROR: retry count over\n'
printf '[285 : 343 WARNING][IPMBIfc.c:752]IPMBIfc.c : Error sending IPMB packet to Slave 0x16\n'
printf 'GetRTCTimeViaESPI L.231: ERROR: retry count exceeded(ret:-1)\n'
printf 'one-off error remains visible\n'
printf '/conf # '
sleep 2
EOF
chmod +x "$tmp/socat"
quiet=$(timeout 0.5 env PATH="$tmp:$PATH" BOX="$box" bash -c '
  _zbmc_resolve_ip() { echo 127.0.0.1; }
  . "$BOX/zbmc.box"
  SOCK=/tmp/fixture.sock
  zbmc_console --nostderr
' || :)
[[ "$quiet" == *'prompt: '* ]]
[[ "$quiet" == *'one-off error remains visible'* ]]
[[ "$quiet" == *'/conf # '* ]]
[[ "$quiet" != *'retry count over'* ]]
[[ "$quiet" != *'Error sending IPMB packet'* ]]
[[ "$quiet" != *'retry count exceeded'* ]]

grep -Fq 'RMCP+ IPMI starts but does not answer' "$box/index.html"
grep -Eq '^irmc-fujitsu[[:space:]]+10\.0\.6\.68$' "$repo/zhosts.txt"
grep -Fq 'irmc-fujitsu' "$repo/qemu/recipes/qemu-11-arm.sh"
