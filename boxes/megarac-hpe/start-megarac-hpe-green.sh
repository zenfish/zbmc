#!/usr/bin/env bash
# start-megarac-hpe-green.sh — boot the Cray XD670 BMC and RETRY until IPMIMain comes up healthy.
#
# WHY: IPMIMain hits a nondeterministic message-handler race under qemu — ~half of cold boots it
#      crash-loops (SIGSEGV x15 -> procmgr reboots the BMC) and ~half it comes up clean (SEGV=0) with
#      IPMI 2.0 RMCP+ + authed Redfish fully working. A good boot is fully green; a bad one never
#      recovers. So we boot, watch for the crash-loop vs healthy signal, and re-roll on a crash-loop.
#      (A warm QMP snapshot of a green instance — like the x14 box — would remove the reroll; TODO.)
#
# HEALTHY  = /tmp/ipmimain_init_done written AND SIGSEGV count stays low (<4) AND `ipmitool mc info`
#            authenticates (admin/superuser). CRASH-LOOP = SIGSEGV count climbs past the threshold.
# RUN: IP=10.0.6.66 WD=/Users/zen/phd/tmp/cray-xd670 ./start-megarac-hpe-green.sh   (prints qemu pid on green)
# ENV: WD (workdir/artifacts), IP (bind IP), HTTPS_PORT/IPMI_PORT (default 443/623), TRIES (default 4).
set -u
WD="${WD:-/Users/zen/phd/tmp/cray-xd670}"
IP="${IP:-10.0.6.66}"
HTTPS_PORT="${HTTPS_PORT:-443}"; SSH_PORT="${SSH_PORT:-22}"; IPMI_PORT="${IPMI_PORT:-623}"
TRIES="${TRIES:-4}"
PROJ="$(cd "$(dirname "$0")" && pwd)"
SUDO=; [ "$(id -u)" = 0 ] || SUDO=sudo
LOG="$WD/svc.log"

# scope to THIS box (hostname=megarac-hpe in its hostfwd) — bare '-M ast2600-evb' kills every ast2600 zoo box.
kill_qemu(){ $SUDO pkill -f 'hostname=megarac-hpe' 2>/dev/null; pkill -f "tail -f $WD/cin" 2>/dev/null; sleep 2; }

for t in $(seq 1 "$TRIES"); do
  echo "[green] boot attempt $t/$TRIES" >&2
  kill_qemu
  HTTPS_PORT="$HTTPS_PORT" SSH_PORT="$SSH_PORT" IPMI_PORT="$IPMI_PORT" BG=1 IP="$IP" WD="$WD" \
    bash "$PROJ/boot-megarac-hpe-svc.sh" >/dev/null 2>&1
  # watch up to ~300s: crash-loop (SEGV>=6) -> reroll; once init_done+Redfish-ready, poll IPMI/Redfish
  # health (RMCP+ + provisioning are slow under emulation) until it passes or the window ends.
  # A healthy boot is SEGV=0; SEGV>=3 means IPMIMain is respawn-looping and won't serve -> reroll fast.
  ok=0
  for i in $(seq 1 100); do
    sleep 3
    segv=$(grep -c 'received SIGSEGV' "$LOG" 2>/dev/null); segv=${segv:-0}   # grep -c exits 1 on 0 matches
    [ "$segv" -ge 3 ] && { echo "[green] attempt $t crash-loop (SEGV=$segv) — reroll" >&2; break; }
    if grep -q 'ipmimain_init_done' "$LOG" 2>/dev/null && grep -q 'Redfish Server ready' "$LOG" 2>/dev/null; then
      # healthy if EITHER IPMI RMCP+ or authed Redfish answers with admin/superuser
      if timeout 22 ipmitool -I lanplus -H "$IP" -p "$IPMI_PORT" -U admin -P superuser mc info 2>/dev/null | grep -q 'Manufacturer' \
         || timeout 12 curl -sk -u admin:superuser "https://$IP:$HTTPS_PORT/redfish/v1/Managers" 2>/dev/null | grep -q ManagerCollection; then
        ok=1; break
      fi
    fi
  done
  if [ "$ok" = 1 ]; then
    qp=$(pgrep -f "hostfwd=udp:$IP:$IPMI_PORT-:623" | head -1)
    echo "[green] HEALTHY on attempt $t (SEGV=$segv) — qemu $qp" >&2
    echo "$qp"; exit 0
  fi
done
echo "[green] no healthy boot in $TRIES tries — IPMIMain race; try again or build a warm snapshot" >&2
exit 1
