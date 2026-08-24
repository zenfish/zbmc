#!/usr/bin/env bash
# restore-idrac10.sh — bring back the warm idrac10 snapshot saved by boot-live-ckpt.sh, in seconds.
# Loads RAM+CPU+device state via -incoming; the frozen overlay (snapshot=on) keeps disk consistent
# with that RAM and makes every restore identical. fullfw is already running in the restored RAM, so
# IPMI on UDP 623 answers immediately — no boot, no dbus lottery.
# NOTE: restored console is LIVE at $W/rserial.sock (root-owned); reach it with `zbmc idrac10 ssh`.
# USAGE: ./restore-idrac10.sh [udp_port] [bind_ip]
#   bind_ip empty  -> hostfwd=udp::PORT-:623  (wildcard, non-root, for testing on 127.0.0.1)
#   bind_ip set    -> hostfwd=udp:BIND:PORT-:623 as root (zbmc real-IP path: 10.0.9.10:623)
# SUCCESS: prints "RESTORE OK: IPMI N/5" with N>0. RELATED: boot-live-ckpt.sh, zbmc.box.
# RELIABILITY: fullfw's migrated UDP socket resumes ~most restores but occasionally comes up silent
# (~1 in 4). So this VERIFIES IPMI and RE-RESTORES (up to $TRIES) until the box actually answers.
set -euo pipefail
cd "${WD:-$(dirname "$0")}"
K=915F32F49A97456D0D6D66EEE5ED84C894B414AF
W="${CKPT:-$PWD/ckpt}"
STATE="$W/state.gz"; OVL="$W/overlay-frozen.qcow2"
SOCK="$W/rserial.sock"; QMP="$W/rqmp.sock"
TRIES="${RESTORE_TRIES:-3}"
[ -f "$STATE" ] || { echo "no snapshot at $STATE — run ./boot-live-ckpt.sh first" >&2; exit 1; }
PORT="${1:-7623}"; BIND="${2:-}"
# real-IP (root) path also forwards tcp:22 -> guest sshd (baked into state.gz); the guest sshd
# binds :22 on $BIND, coexisting with the Mac's wildcard *:22 (specific-IP bind wins for that IP).
if [ -n "$BIND" ]; then HOSTFWD="hostfwd=udp:${BIND}:${PORT}-:623,hostfwd=tcp:${BIND}:22-:22"; VIP="$BIND"; else HOSTFWD="hostfwd=udp::${PORT}-:623"; VIP=127.0.0.1; fi
# privileged port (<1024) or explicit bind IP -> need root (matches zbmc root-direct model)
SUDO=""; { [ "$PORT" -lt 1024 ] || [ -n "$BIND" ]; } && [ "$(id -u)" -ne 0 ] && SUDO="sudo -n"
set +x 2>/dev/null   # keep any inherited xtrace/PS4 out of the console log

# Live progress -> STDERR (which the caller redirects into the console log). Kept off
# STDOUT so `QPID=$(restore_once)` and `ok=$(verify)` capture only the pid / the count.
log(){ printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*" >&2; }

restore_once() {   # launch qemu -incoming, resume, echo the pid (or empty on QMP failure)
  $SUDO pkill -9 -f "$W/rserial.sock" 2>/dev/null || true
  $SUDO pkill -9 -f "$HOSTFWD" 2>/dev/null || true
  sleep 1; $SUDO rm -f "$SOCK" "$QMP" 2>/dev/null; rm -f "$SOCK" "$QMP" 2>/dev/null || true
  # resolve kernel/dtb — build.sh flat layout vs symlinked boot/ subdir
  local _kernel="" _dtb=""
  for _d in boot .; do [ -f "$_d/Image.boot-patched" ] && { _kernel="$_d/Image.boot-patched"; break; }; done
  for _d in boot .; do [ -f "$_d/qemu-gmac.dtb" ]      && { _dtb="$_d/qemu-gmac.dtb";      break; }; done
  [ -n "$_kernel" ] || { log "no Image.boot-patched in boot/ or ."; return 1; }
  $SUDO nohup qemu-system-aarch64 -M npcm845-evb -m 1G \
    -kernel "$_kernel" -dtb "$_dtb" \
    -drive "id=rootsd,if=none,file=$OVL,format=qcow2,snapshot=on" -device sd-card,drive=rootsd,bus=sd-bus \
    -display none -nic user,model=npcm-gmac,"$HOSTFWD" \
    -serial unix:"$SOCK",server,nowait -qmp unix:"$QMP",server,nowait \
    -incoming "exec:gzip -dc < $STATE" \
    >"$W/rqemu.log" 2>&1 &
  local qp=$!; echo "$qp" | $SUDO tee "$W/rqemu.pid" >/dev/null 2>&1 || echo "$qp" >"$W/rqemu.pid"
  log "  qemu -incoming launched (pid $qp) — waiting for QMP…"
  local i; for i in $(seq 1 30); do $SUDO test -S "$QMP" && break; sleep 0.5; done
  $SUDO test -S "$QMP" || { log "  QMP never appeared: $($SUDO tail -1 "$W/rqemu.log" 2>/dev/null)"; $SUDO kill -9 "$qp" 2>/dev/null; return 1; }
  # Resume the vCPU and VERIFY it started. `-incoming` loads PAUSED; a fire-and-forget `cont`
  # that races or fails leaves it paused -> fullfw never runs -> IPMI silent (the 0/5 trap).
  local st
  st=$($SUDO python3 - "$QMP" <<'PY'
import socket, json, sys, time
q = sys.argv[1]
s = socket.socket(socket.AF_UNIX); s.connect(q); f = s.makefile('rw', buffering=1)
def cmd(c):
    f.write(json.dumps(c) + "\n"); f.flush()
    while True:                       # skip async QMP events (RESUME/STOP/MIGRATION) to stay in sync
        r = json.loads(f.readline())
        if "event" not in r:
            return r
f.readline(); cmd({"execute": "qmp_capabilities"})
# 1) WAIT for the incoming migration to finish. `exec:gzip -dc < state.gz` decompresses ~55MB;
#    until it's done, status is "inmigrate" and `cont` is a no-op (the vCPU stays paused).
dl = time.time() + 120; status = ""
while time.time() < dl:
    status = cmd({"execute": "query-status"}).get("return", {}).get("status", "")
    if status != "inmigrate":
        break
    time.sleep(0.5)
# 2) migration done -> cont, and confirm it actually started running.
final = "paused:" + status
for _ in range(20):
    cmd({"execute": "cont"})
    if cmd({"execute": "query-status"}).get("return", {}).get("running"):
        final = "running"; break
    time.sleep(0.5)
print(final)
PY
)
  [ "$st" = running ] || { log "  vCPU failed to resume ($st) — killing this qemu, will re-restore"; $SUDO kill -9 "$qp" 2>/dev/null; return 1; }
  log "  QMP up — migration complete, vCPU running (verified)"
  echo "$qp"
}
verify() {         # N/5 IPMI answers (per-probe progress -> stderr; count -> stdout)
  local n=0 i
  for i in $(seq 1 5); do
    if timeout -s KILL 25 zipmi -H "$VIP" -p "$PORT" -U root -K "$K" -t 20 mc info 2>/dev/null \
         | grep -qiE 'Manufacturer|Device Available'; then
      n=$((n+1)); log "    probe $i/5: answered  (${n}/5 up)"
    else
      log "    probe $i/5: silent"
    fi
  done
  echo "$n"
}

QPID=""; ok=0
for try in $(seq 1 "$TRIES"); do
  log "attempt $try/$TRIES: restoring snapshot…"
  QPID=$(restore_once) || { log "  attempt $try: launch failed — retrying"; continue; }
  sleep 3   # let fullfw's socket re-settle on the new slirp
  log "  verifying IPMI (5 probes on $VIP:$PORT)…"
  ok=$(verify)
  log "  attempt $try result: $ok/5"
  [ "$ok" -gt 0 ] && break
  log "  0/5 (fullfw came up silent) — re-restoring"
  $SUDO kill "$QPID" 2>/dev/null || true
done
if [ "$ok" -gt 0 ]; then
  echo "RESTORE OK: IPMI $ok/5  ($VIP:$PORT, pid $QPID; kill: $SUDO kill $QPID)"
else
  echo "RESTORE FAILED: 0/5 after $TRIES tries (all silent) — box is DOWN; check $W/rqemu.log"
fi
