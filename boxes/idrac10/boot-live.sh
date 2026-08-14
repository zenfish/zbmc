#!/usr/bin/env bash
# boot-live.sh — iDRAC10 Phase 5: boot ONCE to a live, settled fullfw, then LEAVE
# IT RUNNING so live-iterate.sh can reload the LD_PRELOAD shim in seconds instead
# of a full ~11-min rebuild+reboot per change.
#
# WHAT it does (vs run-p5-ipmi.sh which polls then kills qemu on exit):
#   - rebuild shim, sync serve dir, start http.server  (same as run-p5)
#   - launch QEMU DETACHED (nohup; pid -> STATE_DIR/qemu.pid; NOT killed on exit)
#   - drive mount/net/fw.sh over the serial socket to IPMI_READY, then DISCONNECT
#     (fullfw runs under setsid in the guest, so it survives the disconnect)
#   - write STATE_DIR/live.env (SOCK, ports, serve dir) for live-iterate.sh
# SUCCESS: prints "BOX LIVE" + IPMI_READY seen. Box stays up until: ./stop-live.sh
# TARGET: QEMU npcm845-evb, guest fullfw IPMI daemon (RMCP+ / RAKP on UDP 623).
# RELATED: live-iterate.sh (the fast inner loop), LIVE-ITERATE-HANDOFF.md, run-p5-ipmi.sh.
set -euo pipefail
cd "$(dirname "$0")"

WORK_DIR="${HOME}/phd/tmp/idrac10-virtual"
STATE_DIR="${WORK_DIR}/live"
SOCK="${STATE_DIR}/serial.sock"
SERVE_DIR="${WORK_DIR}/serve"
HTTP_PORT=8080
QEMU_IPMI_PORT=7623
LOGFILE="${STATE_DIR}/boot-live.log"

mkdir -p "$WORK_DIR" "$SERVE_DIR" "$STATE_DIR"
exec > >(tee "$LOGFILE") 2>&1

# Refuse to double-boot: one live box per port.
if pgrep -f "hostfwd=udp::${QEMU_IPMI_PORT}-:623" >/dev/null 2>&1; then
  echo "A live box is already using UDP ${QEMU_IPMI_PORT}. ./stop-live.sh first." >&2
  exit 1
fi
[ -S "$SOCK" ] && rm -f "$SOCK"

# Rebuild shim from source (fresh binary; no stale .so).
zig cc -shared -fPIC -o "${SERVE_DIR}/shm-shim.so" shm-shim.c \
    -target aarch64-linux-gnu -ldl -lpthread -O2
cp "${SERVE_DIR}/shm-shim.so" shm-shim.so
echo "[+] shm-shim.so rebuilt ($(stat -f%z "${SERVE_DIR}/shm-shim.so") bytes)"

cp boot-fullfw-guest.sh fake-journal udp-echo cfgdb-defaults.sql "$SERVE_DIR/"
cp prebind-v2 "${SERVE_DIR}/prebind"
echo "[+] guest binaries synced to $SERVE_DIR"

# http.server (detached; live-iterate wgets the fresh shim from here each cycle).
pkill -f "http.server ${HTTP_PORT}" 2>/dev/null || true
nohup python3 -m http.server "$HTTP_PORT" --directory "$SERVE_DIR" \
    >"${STATE_DIR}/httpd.log" 2>&1 &
echo "[+] http.server on :${HTTP_PORT} (pid $!)"

# QEMU DETACHED — nohup + disown so it outlives this script (macOS has no setsid).
# NOT trap-killed: the whole point is the box stays up for live-iterate.
nohup qemu-system-aarch64 \
  -M npcm845-evb -m 1G \
  -kernel boot/Image.boot-patched \
  -dtb boot/qemu-gmac.dtb \
  -drive "id=rootsd,if=none,file=img/sd.img,format=raw,snapshot=on" \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -display none \
  -nic user,model=npcm-gmac,"hostfwd=udp::${QEMU_IPMI_PORT}-:623" \
  -serial unix:"${SOCK}",server,nowait \
  >"${STATE_DIR}/qemu.log" 2>&1 &
QPID=$!
disown "$QPID" 2>/dev/null || true
echo "$QPID" > "${STATE_DIR}/qemu.pid"

until [ -S "$SOCK" ]; do sleep 0.5; done
sleep 1
echo "[+] QEMU started detached (pid=$QPID); serial=$SOCK"

# Drive the guest bring-up to IPMI_READY over the serial socket, then DISCONNECT.
# fullfw runs under setsid in the guest → survives this disconnect.
expect << 'EOEXP'
match_max 2000000
set timeout 60
spawn socat - UNIX-CONNECT:$env(HOME)/phd/tmp/idrac10-virtual/live/serial.sock

expect { "sh-5.2#" {} timeout { puts "BOOT TIMEOUT"; exit 1 } }
puts "\[boot-live] shell ready"

send "mount -t proc proc /proc; mount -t sysfs sysfs /sys; mount -t devtmpfs devtmpfs /dev; mkdir -p /dev/pts; mount -t devpts devpts /dev/pts; mount -t tmpfs tmpfs /tmp; mount -t tmpfs tmpfs /run; mount -t tmpfs tmpfs /var/volatile; mount -t tmpfs tmpfs /mnt\r"
expect -timeout 15 "sh-5.2#"
puts "\[boot-live] filesystems mounted"

send "ip link set eth0 up; ip addr add 10.0.2.15/24 dev eth0; ip route add default via 10.0.2.2\r"
expect -timeout 210 "sh-5.2#"
puts "\[boot-live] network up"

puts "\[boot-live] starting fw.sh..."
send "wget -q --timeout=15 http://10.0.2.2:8080/boot-fullfw-guest.sh -O /tmp/fw.sh && sh /tmp/fw.sh 2>&1\r"
expect {
    -timeout 600
    "IPMI_READY" { puts "\[boot-live] IPMI_READY matched" }
    timeout { puts "\[boot-live] TIMEOUT waiting for IPMI_READY"; exit 1 }
    eof    { puts "\[boot-live] EOF before IPMI_READY"; exit 1 }
}
# let fw.sh return to a prompt, then leave the shell idle & disconnect
expect -timeout 30 "sh-5.2#"
puts "\[boot-live] fullfw settled; disconnecting (box stays up)"
exit 0
EOEXP

# Persist state for live-iterate.sh
cat > "${STATE_DIR}/live.env" <<ENV
SOCK=${SOCK}
SERVE_DIR=${SERVE_DIR}
HTTP_PORT=${HTTP_PORT}
QEMU_IPMI_PORT=${QEMU_IPMI_PORT}
QEMU_PID=${QPID}
ENV

echo
echo "=== BOX LIVE ==="
echo "  qemu pid : ${QPID}  (serial ${SOCK})"
echo "  iterate  : ./live-iterate.sh            # rebuild shim + reload fullfw, poll IPMI"
echo "  stop     : ./stop-live.sh"
