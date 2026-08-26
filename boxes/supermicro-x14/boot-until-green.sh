#!/usr/bin/env bash
#
# boot-until-green.sh — cold-boot the virtual X14 (normal systemd) repeatedly until ONE
# boot reaches green (Redfish answers on 10.0.8.14), then LEAVE IT RUNNING for live use.
#
# WHY: cold boot is nondeterministic under emulation (daemons wedge at a different spot
# each boot). A green boot demonstrably exists (that's how ckpt/state.gz was captured).
# Unlike the warm restore (network-DEAD post -incoming), a live green cold boot has a
# working guest network -> external ipmitool + curl work. So we brute-force catch one.
#
# Console -> /tmp/x14-boot.log (root-owned; read via sudo) for wedge detection.
# On green: exits 0 with qemu still running. Test:
#   curl -sk https://10.0.8.14/redfish/v1/ ; ipmitool -I lanplus -H 10.0.8.14 -U ADMIN -P ADMIN mc info
#
set -uo pipefail
cd "$(dirname "$0")"
IP="${ZBMC_IP:-10.0.8.14}"; QEMU="${QEMU:-$(command -v qemu-system-arm || echo /opt/homebrew/bin/qemu-system-arm)}"; MAX=${1:-8}
CONSOLE_LOG="${ZBMC_CONSOLE_LOG:-/tmp/x14-boot.log}"
case "$(uname -s)" in Darwin) ifconfig lo0 | grep -q "$IP" || sudo ifconfig lo0 alias "$IP";; *) ip addr show dev lo | grep -q "$IP" || sudo ip addr add "$IP/32" dev lo;; esac
MASKS="systemd.mask=bmc-shared-lan-discovery.service systemd.mask=com.Supermicro.CPLDInit.service \
systemd.mask=fan-boot-control.service systemd.mask=obmc-flash-bmc-setenv@.service \
systemd.mask=sshdgenkeys.service systemd.mask=checkuid.service systemd.mask=clear-once.service \
systemd.mask=systemd-networkd-wait-online.service systemd.mask=com.Supermicro.LeakageManager.service"

for try in $(seq 1 "$MAX"); do
  echo "=== attempt $try/$MAX ==="
  sudo -n pkill -9 -f "ast2600-evb" 2>/dev/null; sleep 2
  sudo -n rm -f /tmp/x14-boot.log /tmp/x14-qmp.sock
  if [ "$try" -gt 1 ] && sudo -n test -f "$CONSOLE_LOG"; then
    sudo -n cp -f "$CONSOLE_LOG" "$(dirname "$CONSOLE_LOG")/console-attempt-$((try-1)).log"
  fi
  sudo -n "$QEMU" -m 1024 -M ast2600-evb -display none -no-reboot \
    -serial "file:$CONSOLE_LOG" \
    -qmp unix:/tmp/x14-qmp.sock,server,nowait \
    -kernel kernel.bin -dtb x14-noncsi.dtb -initrd initramfs-patched.bin \
    -drive file=x14-ce0-64m.img,format=raw,if=mtd \
    -drive file=emmc.img,format=raw,if=sd,index=2 \
    -net nic -net user,hostfwd=tcp:$IP:${SSH_PORT:-22}-:22,hostfwd=tcp:$IP:${WEB_PORT:-443}-:443,hostfwd=udp:$IP:623-:623,hostname=x14bmc \
    -append "console=ttyS4,115200n8 root=/dev/ram rw maxcpus=1 initcall_blacklist=ast2600_spitee_init,optee_driver_init qemu-x14-ramroot $MASKS loglevel=7" &
  sleep 3
  prev=0; stall=0
  for i in $(seq 1 45); do          # up to ~4.5 min/attempt
    sleep 6
    pgrep -f ast2600-evb >/dev/null || { echo "  qemu died early"; break; }
    code=$(curl -sk --max-time 4 -o /dev/null -w "%{http_code}" "https://$IP/redfish/v1/" 2>/dev/null)
    if [ "$code" = 200 ] || [ "$code" = 404 ] || [ "$code" = 301 ] || [ "$code" = 302 ]; then
      echo "=== GREEN on attempt $try (redfish=$code) — leaving qemu running ==="
      exit 0
    fi
    cur=$(sudo -n cat "$CONSOLE_LOG" 2>/dev/null | wc -l | tr -d ' ')
    lastln=$(sudo -n tail -1 "$CONSOLE_LOG" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g;s/\r//g' | cut -c1-50)
    if [ "$cur" = "$prev" ]; then stall=$((stall+1)); else stall=0; fi
    prev=$cur
    echo "  ${i}: redfish=$code lines=$cur stall=$stall | $lastln"
    [ "$stall" -ge 10 ] && { echo "  wedged (~60s no console progress), retrying"; break; }
  done
done
echo "=== no green boot in $MAX attempts ==="
exit 1
