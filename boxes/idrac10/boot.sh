#!/usr/bin/env bash
# boot.sh — restore the iDRAC10 warm snapshot: launch qemu -incoming (paused), then resume the vCPU.
#
# Cold-booting iDRAC10 is a dbus-broker socket-activation lottery under single-vCPU TCG, so we don't —
# we resume a known-good captured state. NPCM845 gmac migrates cleanly, so the network survives with it.
# NOTE: pinned to qemu-system-aarch64 11.x — a different qemu build will fail to load the migration state.
set -u
_HERE="$(cd "$(dirname "$0")" && pwd)"; _REPO="$(cd "$_HERE/../.." && pwd)"
WD="${WD:-$_REPO/work/$(basename "$_HERE")}"
IP="${IP:-127.0.0.1}"
SSH_PORT="${SSH_PORT:-7022}"; HTTPS_PORT="${HTTPS_PORT:-7443}"; IPMI_PORT="${IPMI_PORT:-7623}"
for f in Image.boot-patched qemu-gmac.dtb overlay-frozen.qcow2 state.gz; do
  [ -f "$WD/$f" ] || { echo "missing $WD/$f — run ./build.sh idrac10 first"; exit 1; }
done
SOCK="$WD/rserial.sock"; QMP="$WD/rqmp.sock"; rm -f "$SOCK" "$QMP"

qemu-system-aarch64 -M npcm845-evb -m 1G \
  -kernel "$WD/Image.boot-patched" -dtb "$WD/qemu-gmac.dtb" \
  -drive "id=rootsd,if=none,file=$WD/overlay-frozen.qcow2,format=qcow2,snapshot=on" \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -display none \
  -nic "user,model=npcm-gmac,hostfwd=udp:$IP:$IPMI_PORT-:623,hostfwd=tcp:$IP:$SSH_PORT-:22,hostfwd=tcp:$IP:$HTTPS_PORT-:443" \
  -serial "unix:$SOCK,server,nowait" -qmp "unix:$QMP,server,nowait" \
  -incoming "exec:gzip -dc < $WD/state.gz" > "$WD/svc.log" 2>&1 &
QP=$!

# wait for the QMP socket, then resume the migrated vCPU — loop cont until it reports running
# (a just-migrated vCPU often needs several cont attempts before it actually resumes).
for i in $(seq 1 60); do [ -S "$QMP" ] && break; sleep 0.25; done
python3 - "$QMP" <<'PY' 2>/dev/null
import socket,sys,json,time
s=socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); f=s.makefile('rw')
def cmd(c): f.write(json.dumps(c)+"\r\n"); f.flush(); return json.loads(f.readline())
f.readline()                                   # greeting
cmd({"execute":"qmp_capabilities"})
for _ in range(25):
    cmd({"execute":"cont"})
    if cmd({"execute":"query-status"}).get("return",{}).get("running"): break
    time.sleep(0.3)
PY
echo "$QP"
