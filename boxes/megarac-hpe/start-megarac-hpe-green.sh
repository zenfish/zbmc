#!/usr/bin/env bash
# start-megarac-hpe-green.sh — boot the Cray XD670 BMC and RETRY until IPMIMain comes up healthy.
#
# WHY: After a patch (KCS disabled + early rc-init-complete), cold boots mostly stabilize within 2 early
#      IPMIMain SIGSEGVs then come up clean. Occasionally a boot still crash-loops (>2 SIGSEGVs); this
#      script re-rolls in that case. Prefer restore-megarac-hpe.sh (warm snap, ~10s) over cold-boot rerolls.
#      Cold-boot is needed only if no snapshot exists or the flash needs to be reset.
#
# HEALTHY  = authenticated IPMI and Redfish ServiceRoot both work without an IPMIMain SIGSEGV.
# RUN: IP=10.0.6.66 WD=/Users/zen/phd/tmp/cray-xd670 ./start-megarac-hpe-green.sh   (prints qemu pid on green)
# ENV: WD (workdir/artifacts), IP (bind IP), HTTPS_PORT/IPMI_PORT (default 443/623), TRIES (default 4).
set -u
WD="${WD:-$(cd "$(dirname "$0")/../.." && pwd)/work/megarac-hpe}"
IP="${ZBMC_IP:-${IP:-10.0.6.66}}"
HTTPS_PORT="${HTTPS_PORT:-443}"; SSH_PORT="${SSH_PORT:-22}"; TELNET_PORT="${TELNET_PORT:-23}"; IPMI_PORT="${IPMI_PORT:-623}"
TRIES="${TRIES:-4}"
PROJ="$(cd "$(dirname "$0")" && pwd)"
ZIPMI="${ZIPMI:-$(cd "$PROJ/../../.." && pwd)/zipmi}"
SUDO=; [ "$(id -u)" = 0 ] || SUDO=sudo
LOG="${ZBMC_CONSOLE_LOG:-$WD/svc.log}"

# scope to THIS box (hostname=megarac-hpe in its hostfwd) — bare '-M ast2600-evb' kills every ast2600 zoo box.
kill_qemu(){ $SUDO pkill -f 'hostname=megarac-hpe' 2>/dev/null; pkill -f "tail -f $WD/cin" 2>/dev/null; sleep 2; }

for t in $(seq 1 "$TRIES"); do
  echo "[green] boot attempt $t/$TRIES" >&2
  if [ "$t" -gt 1 ] && [ -f "$LOG" ]; then
    cp -f "$LOG" "$(dirname "$LOG")/console-attempt-$((t-1)).log"
  fi
  kill_qemu
  HTTPS_PORT="$HTTPS_PORT" SSH_PORT="$SSH_PORT" TELNET_PORT="$TELNET_PORT" IPMI_PORT="$IPMI_PORT" BG=1 IP="$IP" WD="$WD" \
    bash "$PROJ/boot-megarac-hpe-svc.sh" >/dev/null 2>&1
  # Watch up to ~300s for authenticated IPMI and Redfish or an exact fatal signature.
  # The console always contains unrelated bare "Segmentation fault" lines from early
  # SKU/FRU helpers, so those are not evidence that IPMIMain died.  IPMIMain redirects
  # stderr and records its own faults in crit.log; the external authenticated health
  # check below is the authoritative gate.
  ok=0
  for i in $(seq 1 100); do
    sleep 3
    if grep -qE 'Thread [0-9]+ \(MsgHndlr\) received SIGSEGV|IPMIMain is terminating because of SIGSEGV' "$LOG" 2>/dev/null; then
      echo "[green] attempt $t: console confirmed IPMIMain MsgHndlr SIGSEGV — reroll" >&2
      break
    fi
    # Once dropbear is reachable, use IPMIMain's own signal-handler record as the
    # authoritative fast-fail.  This avoids waiting the full five-minute window on
    # a proven-dead attempt while ignoring unrelated SKU/FRU console segfaults.
    if timeout -s KILL 6 sshpass -p '' ssh \
         -o ConnectTimeout=2 -o ConnectionAttempts=1 \
         -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
         -p "$SSH_PORT" "sysadmin@$IP" \
         'grep -q "IPMIMain.*MsgHndlr.*SIGSEGV" /var/log/crit.log' 2>/dev/null; then
      echo "[green] attempt $t: confirmed IPMIMain MsgHndlr SIGSEGV — reroll" >&2
      break
    fi
    # Internal init markers are incomplete on otherwise functional boots. Every
    # 15 seconds, use the same external protocol evidence zbmc status relies on.
    if [ $((i % 5)) = 0 ] &&
       timeout -s KILL 35 env PYTHONPATH="$ZIPMI" python3 -m zipmi.cli.zipmi \
         -H "$IP" -p "$IPMI_PORT" -U admin -P superuser -t 20 mc info 2>/dev/null | grep -q Manufacturer &&
       timeout 20 curl -sk --max-time 15 -u admin:superuser \
         "https://$IP:$HTTPS_PORT/redfish/v1/" 2>/dev/null | grep -q '"RedfishVersion"'; then
      ok=1; break
    fi
  done
  if [ "$ok" = 1 ]; then
    qp=$(pgrep -f "hostfwd=udp:$IP:$IPMI_PORT-:623" | head -1)
    echo "[green] HEALTHY on attempt $t — qemu $qp" >&2
    echo "$qp"; exit 0
  fi
done
echo "[green] no healthy boot in $TRIES tries — IPMIMain race; try again or build a warm snapshot" >&2
exit 1
