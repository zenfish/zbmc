#!/usr/bin/env bash
# boot-live-ckpt.sh — boot idrac10 until a GOOD boot (fullfw up, IPMI answers), then SNAPSHOT
# that state to a file. Pays the dbus-broker lottery (~1/3 boots come up) ONCE; every later
# `restore-idrac10.sh` brings back a warm box answering IPMI on UDP 623 in seconds.
#
# WHY a persistent qcow2 overlay (not snapshot=on): migrate saves RAM+CPU+devices; the disk must
#   be consistent with that RAM on restore. The overlay holds all boot-time writes (/flash,/etc)
#   and is frozen at snapshot; restore re-attaches it with snapshot=on so every restore is identical.
# NOTE: the restored guest's console is LIVE at ckpt/rserial.sock (reach it via `zbmc idrac10 ssh`);
#   this script drives the box over IPMI/UDP regardless.
# USAGE: ./boot-live-ckpt.sh [max_boot_attempts]   (default 4)
# SUCCESS: prints "SNAPSHOT SAVED <file>" after a verified 623 answer. Retries bad (dbus-hung) boots.
# RELATED: restore-idrac10.sh, probe-migrate.sh, boot-live.sh, ckpt (idrac9-virtual/ckpt.py).
set -euo pipefail
cd "${WD:-$(dirname "$0")}"
ATTEMPTS="${1:-4}"
K=915F32F49A97456D0D6D66EEE5ED84C894B414AF
W="${CKPT:-$PWD/ckpt}"; mkdir -p "$W"
SERVE="${HOME}/phd/tmp/idrac10-virtual/serve"; mkdir -p "$SERVE"
OVL="$W/overlay.qcow2"; STATE="$W/state.gz"
SOCK="$W/serial.sock"; QMP="$W/qmp.sock"
PORT=7623
QEMU="${ZBMC_QEMU:-qemu-system-aarch64}"

zig cc -shared -fPIC -o "$SERVE/shm-shim.so" shm-shim.c -target aarch64-linux-gnu -ldl -lpthread -O2
cp shm-shim.so "$SERVE/shm-shim.so" 2>/dev/null || true
cp boot-fullfw-guest.sh fake-journal udp-echo cfgdb-defaults.sql prebind-v2 "$SERVE/" 2>/dev/null || true
cp prebind-v2 "$SERVE/prebind"
pkill -f "http.server 8080" 2>/dev/null || true
nohup python3 -m http.server 8080 --directory "$SERVE" >"$W/httpd.log" 2>&1 &

for attempt in $(seq 1 "$ATTEMPTS"); do
  echo "=== BOOT ATTEMPT $attempt/$ATTEMPTS ==="
  pkill -9 -f "$W/serial.sock" 2>/dev/null || true
  pkill -9 -f "hostfwd=udp::${PORT}-:623" 2>/dev/null || true
  sleep 1; rm -f "$SOCK" "$QMP" "$OVL"
  qemu-img create -f qcow2 -F raw -b "$(pwd)/img/sd.img" "$OVL" >/dev/null
  nohup "$QEMU" -M npcm845-evb -m 1G \
    -kernel boot/Image.boot-patched -dtb boot/qemu-gmac.dtb \
    -drive "id=rootsd,if=none,file=$OVL,format=qcow2" -device sd-card,drive=rootsd,bus=sd-bus \
    -display none -nic user,model=npcm-gmac,"hostfwd=udp::${PORT}-:623" \
    -serial unix:"$SOCK",server,nowait -qmp unix:"$QMP",server,nowait \
    >"$W/qemu.log" 2>&1 &
  QPID=$!
  for i in $(seq 1 30); do [ -S "$SOCK" ] && break; sleep 0.5; done
  # drive bring-up; feed the UDP-echo prime like zbmc.box does
  ( for i in $(seq 1 240); do grep -q UDP_ECHO_READY "$W/boot.log" 2>/dev/null && { \
      python3 -c "import socket;s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM);s.sendto(b'HELLO_UDP_TEST',('127.0.0.1',$PORT))" 2>/dev/null; break; }; sleep 0.5; done ) &
  set +e
  expect -c "
    match_max 2000000
    set timeout 60
    spawn socat - UNIX-CONNECT:$SOCK
    expect { \"sh-5.2#\" {} timeout { puts BOOT_TIMEOUT; exit 1 } }
    send \"mount -t proc proc /proc; mount -t sysfs sysfs /sys; mount -t devtmpfs devtmpfs /dev; mkdir -p /dev/pts; mount -t devpts devpts /dev/pts; mount -t tmpfs tmpfs /tmp; mount -t tmpfs tmpfs /run; mount -t tmpfs tmpfs /var/volatile; mount -t tmpfs tmpfs /mnt\r\"
    expect -timeout 15 \"sh-5.2#\"
    send \"ip link set eth0 up; ip addr add 10.0.2.15/24 dev eth0; ip route add default via 10.0.2.2\r\"
    expect -timeout 210 \"sh-5.2#\"
    send \"wget -q --timeout=15 http://10.0.2.2:8080/boot-fullfw-guest.sh -O /tmp/fw.sh && sh /tmp/fw.sh 2>&1\r\"
    expect { -timeout 600 \"IPMI_READY\" { puts FW_OK } timeout { puts FW_TIMEOUT; exit 2 } eof { puts FW_EOF; exit 2 } }
    expect -timeout 30 \"sh-5.2#\"
    exit 0
  " > "$W/boot.log" 2>&1
  rc=$?
  set -e
  grep -aE 'FW_OK|FW_TIMEOUT|FW_EOF|BOOT_TIMEOUT' "$W/boot.log" | tail -1 || true
  if [ $rc -ne 0 ]; then echo "  bad boot (rc=$rc) — retrying"; kill "$QPID" 2>/dev/null || true; continue; fi

  echo "  fw.sh done — verifying IPMI on :$PORT"
  ok=0; for i in $(seq 1 6); do
    timeout -s KILL 25 zipmi -H 127.0.0.1 -p "$PORT" -U root -K "$K" -t 20 mc info 2>/dev/null \
      | grep -qiE 'Manufacturer|Device Available' && ok=$((ok+1))
  done
  echo "  IPMI verify: $ok/6"
  if [ $ok -lt 3 ]; then echo "  IPMI weak — retrying"; kill "$QPID" 2>/dev/null || true; continue; fi

  echo "  GOOD BOX — snapshotting via QMP"
  python3 - "$QMP" "$STATE" <<'PY'
import socket,json,sys,time
qmp,out=sys.argv[1],sys.argv[2]
s=socket.socket(socket.AF_UNIX);s.connect(qmp);f=s.makefile('rw',buffering=1)
f.readline();f.write(json.dumps({"execute":"qmp_capabilities"})+"\n");f.flush();f.readline()
def rpc(o):
    f.write(json.dumps(o)+"\n");f.flush()
    while True:
        r=json.loads(f.readline())
        if "return" in r or "error" in r: return r
rpc({"execute":"migrate-set-parameters","arguments":{"max-bandwidth":8<<30}})
rpc({"execute":"stop"})
r=rpc({"execute":"migrate","arguments":{"uri":"exec:gzip -c > %s"%out}})
if "error" in r: print("MIGRATE_ERR",r["error"]); sys.exit(1)
for _ in range(240):
    st=rpc({"execute":"query-migrate"}).get("return",{})
    if st.get("status") in ("completed","failed","cancelled"):
        print("MIGRATE",st.get("status")); break
    time.sleep(0.5)
rpc({"execute":"cont"})  # resume source (leave box up)
PY
  ls -lh "$STATE" | awk '{print "  state:",$5}'
  # freeze the overlay for repeatable restores
  cp "$OVL" "$W/overlay-frozen.qcow2"
  echo "SNAPSHOT SAVED $STATE  (overlay $W/overlay-frozen.qcow2)"
  echo "SOURCE BOX still live on :$PORT (pid $QPID). restore: ./restore-idrac10.sh"
  exit 0
done
echo "NO GOOD BOOT in $ATTEMPTS attempts (dbus lottery lost every time)"; exit 1
