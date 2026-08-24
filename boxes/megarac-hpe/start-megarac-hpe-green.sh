#!/usr/bin/env bash
# start-megarac-hpe-green.sh — boot the Cray XD670 BMC and RETRY until IPMIMain comes up healthy.
#
# WHY: After a patch (KCS disabled + early rc-init-complete), cold boots mostly stabilize within 2 early
#      IPMIMain SIGSEGVs then come up clean. Occasionally a boot still crash-loops (>2 SIGSEGVs); this
#      script re-rolls in that case. Prefer restore-megarac-hpe.sh (warm snap, ~10s) over cold-boot rerolls.
#      Cold-boot is needed only if no snapshot exists or the flash needs to be reset.
#
# HEALTHY  = /tmp/ipmimain_init_done + /tmp/restservice_init_done written AND SIGSEGV count stays low
#            (<4) AND authed Redfish (/redfish/v1/Managers) returns 200. CRASH-LOOP = SIGSEGV > threshold.
# RUN: IP=10.0.6.66 WD=/Users/zen/phd/tmp/cray-xd670 ./start-megarac-hpe-green.sh   (prints qemu pid on green)
# ENV: WD (workdir/artifacts), IP (bind IP), HTTPS_PORT/IPMI_PORT (default 443/623), TRIES (default 4).
set -u
WD="${WD:-/Volumes/xxx/src/me/git/vbmc-lab/work/megarac-hpe}"
IP="${ZBMC_IP:-${IP:-10.0.6.66}}"
HTTPS_PORT="${HTTPS_PORT:-443}"; SSH_PORT="${SSH_PORT:-22}"; TELNET_PORT="${TELNET_PORT:-23}"; IPMI_PORT="${IPMI_PORT:-623}"
TRIES="${TRIES:-4}"
PROJ="$(cd "$(dirname "$0")" && pwd)"
SUDO=; [ "$(id -u)" = 0 ] || SUDO=sudo
LOG="$WD/svc.log"

# scope to THIS box (hostname=megarac-hpe in its hostfwd) — bare '-M ast2600-evb' kills every ast2600 zoo box.
kill_qemu(){ $SUDO pkill -f 'hostname=megarac-hpe' 2>/dev/null; pkill -f "tail -f $WD/cin" 2>/dev/null; sleep 2; }

for t in $(seq 1 "$TRIES"); do
  echo "[green] boot attempt $t/$TRIES" >&2
  if [ "$t" -gt 1 ] && [ -f "$LOG" ]; then
    cp -f "$LOG" "$WD/svc-attempt-$((t-1)).log"
  fi
  kill_qemu
  HTTPS_PORT="$HTTPS_PORT" SSH_PORT="$SSH_PORT" TELNET_PORT="$TELNET_PORT" IPMI_PORT="$IPMI_PORT" BG=1 IP="$IP" WD="$WD" \
    bash "$PROJ/boot-megarac-hpe-svc.sh" >/dev/null 2>&1
  # watch up to ~300s; once init_done+Redfish-ready, poll authenticated Redfish.
  # health (RMCP+ + provisioning are slow under emulation) until it passes or the window ends.
  # The console always contains unrelated bare "Segmentation fault" lines from early
  # SKU/FRU helpers, so those are not evidence that IPMIMain died.  IPMIMain redirects
  # stderr and records its own faults in crit.log; the external authenticated health
  # check below is the authoritative gate.
  ok=0
  for i in $(seq 1 100); do
    sleep 3
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
    # The firmware's own boot-complete check can report FAIL before LAN provisioning
    # finishes.  Record it in the console log, but do not treat that transient as a
    # terminal result; authenticated Redfish below is the actual readiness gate.
    if grep -q 'ipmimain_init_done' "$LOG" 2>/dev/null && grep -q 'Redfish Server ready' "$LOG" 2>/dev/null; then
      # Poke RMCP+ once — IPMIMain's LAN init is lazy under emulation; a single UDP packet
      # triggers it and causes admin/superuser provisioning into UserConfig.ini. Without this,
      # no user exists and Redfish returns AccessDenied. python3+socket is always available.
      python3 -c "
import socket,struct
# RMCP Get Channel Auth Capabilities (no session required)
pkt = bytes([0x06,0x00,0xff,0x07,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x09,
             0x20,0x18,0xc8,0x81,0x00,0x38,0x8e,0x04,0x31])
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.settimeout(2); s.sendto(pkt, ('$IP', $IPMI_PORT)); s.close()
" 2>/dev/null || true
      sleep 8
      if timeout 35 curl -sk --max-time 30 -u admin:superuser "https://$IP:$HTTPS_PORT/redfish/v1/Managers" 2>/dev/null | grep -q ManagerCollection; then
        ok=1; break
      fi
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
