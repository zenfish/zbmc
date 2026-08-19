#!/usr/bin/env bash
#
# snapshot-x14.sh — QMP-checkpoint the running virtual X14 to a gz file (fast-retry base).
#
# WHAT:  Migrates the live qemu (RAM+device state) to ckpt via QMP exec:gzip, so it can be
#        restored in ~10s instead of a ~55s cold boot. VERIFIED: the SVC-mode ast2600 boot
#        restores with a LIVE network (UDP 623 + TCP 443 both survive -incoming) — unlike the
#        earlier normal-boot checkpoint which came up network-dead.
# WHY:   Iterating on bmcweb/daemon bringup needs a clean, un-churned base to restore to each
#        try (the guest state poisons quickly under repeated daemon restarts — pristine lesson).
# USAGE: snapshot-x14.sh [outfile]     (default: svc-snap.gz)   VM is PAUSED after; kill+restore.
# PAIR:  restore-svc-x14.sh loads it.
#
set -euo pipefail
cd "${WD:-$(dirname "$0")}"
OUT="${1:-svc-snap.gz}"
QMP=/tmp/x14-qmp.sock
sudo -n chmod 666 "$QMP" 2>/dev/null || true
python3 - "$OUT" "$QMP" <<'PY'
import socket,json,time,os,sys
OUT,QMP=sys.argv[1],sys.argv[2]
s=socket.socket(socket.AF_UNIX); s.settimeout(120); s.connect(QMP); s.recv(65536)
def q(c): s.sendall((json.dumps(c)+"\n").encode()); return s.recv(65536).decode()
q({"execute":"qmp_capabilities"})
q({"execute":"migrate-set-parameters","arguments":{"max-bandwidth":4<<30}})
q({"execute":"migrate","arguments":{"uri":f"exec:gzip -c > {os.path.abspath(OUT)}"}})
st=None
for _ in range(120):
    r=json.loads(q({"execute":"query-migrate"}).strip()); st=r.get("return",{}).get("status")
    if st in ("completed","failed","cancelled"): break
    time.sleep(1)
print("snapshot:",st, os.path.getsize(OUT)//1024//1024,"MB ->",OUT)
PY
