#!/usr/bin/env bash
# snapshot-megarac-hpe.sh — QMP-checkpoint a GREEN running Cray XD670 BMC to a gz (warm-restore base).
#
# WHY: IPMIMain hits a nondeterministic crash race, so only some cold boots come up green. Once we
#      DO have a green instance (IPMIMain stable, admin/superuser IPMI+Redfish working), snapshot it;
#      restore-megarac-hpe.sh then brings that exact green state back in ~10s every time — no reroll.
# WHAT: QMP `migrate` -> exec:gzip captures RAM + device state to cray-snap.gz (VM is PAUSED after).
#       The mtd flash holds the provisioned /conf (admin user), so we also copy it to cray-snap-flash.bin
#       — restore must re-attach the matching flash. Take the snapshot only AFTER verifying green.
# USAGE: WD=/path/to/work/megarac-hpe ./snapshot-megarac-hpe.sh   (qemu must be running with -qmp)
# PAIR:  restore-megarac-hpe.sh loads it. Snapshot files stay in WD (large; not git — regen via a green boot).
set -euo pipefail
umask 077
HERE="$(cd "$(dirname "$0")" && pwd)"
WD="${WD:-$(cd "$HERE/../.." && pwd)/work/megarac-hpe}"
OUT="${1:-$WD/cray-snap.gz}"
QMP="$WD/cray-qmp.sock"
[ -S "$QMP" ] || { echo "no QMP socket at $QMP — is a -qmp boot running?" >&2; exit 1; }
sudo -n chmod 600 "$QMP" 2>/dev/null || true
python3 - "$OUT" "$QMP" <<'PY'
import socket,json,time,os,shlex,sys
OUT,QMP=sys.argv[1],sys.argv[2]
s=socket.socket(socket.AF_UNIX); s.settimeout(180); s.connect(QMP); s.recv(65536)
def q(c): s.sendall((json.dumps(c)+"\n").encode()); return s.recv(65536).decode()
q({"execute":"qmp_capabilities"})
q({"execute":"migrate-set-parameters","arguments":{"max-bandwidth":4<<30}})
q({"execute":"migrate","arguments":{"uri":f"exec:gzip -c > {shlex.quote(os.path.abspath(OUT))}"}})
st=None
for _ in range(180):
    r=json.loads(q({"execute":"query-migrate"}).strip()); st=r.get("return",{}).get("status")
    if st in ("completed","failed","cancelled"): break
    time.sleep(1)
print("snapshot:",st, os.path.getsize(OUT)//1024//1024,"MB ->",OUT)
if st!="completed": sys.exit(1)
PY
# preserve the exact flash (provisioned /conf) that pairs with this RAM snapshot
cp -f "$WD/mtdflash-run.bin" "$WD/cray-snap-flash.bin"
echo "snapshot flash -> $WD/cray-snap-flash.bin  (VM is paused; kill it, then restore-megarac-hpe.sh)"
