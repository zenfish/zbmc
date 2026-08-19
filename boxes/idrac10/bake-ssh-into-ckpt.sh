#!/usr/bin/env bash
# bake-ssh-into-ckpt.sh — re-snapshot the *currently running* warm idrac10 into state.gz so the
# live guest state (root sshd + host keys + world-readable authorized_keys + the files-first
# nsswitch bind — all in tmpfs/RAM) survives every future `zbmc idrac10 start`.
#
# WHY this works without a cold reboot: the ssh bring-up wrote only tmpfs paths (/mnt,/run,/tmp),
# so the frozen overlay (overlay-frozen.qcow2) is still byte-consistent with the new RAM image.
# We just migrate RAM+CPU+devices again over the top of state.gz. The tcp:22 hostfwd is NOT in the
# RAM image (it's a qemu netdev arg) — restore-idrac10.sh adds it; boot-fullfw-guest.sh carries the
# guest-side setup for future *cold* re-snapshots (boot-live-ckpt.sh).
#
# USAGE:   ./bake-ssh-into-ckpt.sh
# SUCCESS: prints "BAKED: state.gz updated (MIGRATE completed)". Backs up the old state.gz first.
# BACKOUT: mv the printed *.prebake-*.bak back over state.gz. RELATED: restore-idrac10.sh, boot-live-ckpt.sh.
set -euo pipefail
W="${HOME}/phd/tmp/idrac10-virtual/ckpt"
STATE="$W/state.gz"; QMP="$W/rqmp.sock"
[ -S "$QMP" ] || { echo "no live QMP at $QMP — is the warm idrac10 running? (zbmc idrac10 start)" >&2; exit 1; }
[ -f "$STATE" ] || { echo "no $STATE to back up" >&2; exit 1; }

BAK="$STATE.prebake-$(date +%Y%m%d-%H%M%S).bak"
cp "$STATE" "$BAK"
echo "backed up old snapshot -> $BAK"

SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo -n"
$SUDO python3 - "$QMP" "$STATE" <<'PY'
import socket, json, sys, time
qmp, out = sys.argv[1], sys.argv[2]
s = socket.socket(socket.AF_UNIX); s.connect(qmp); f = s.makefile('rw', buffering=1)
def rpc(o):
    f.write(json.dumps(o) + "\n"); f.flush()
    while True:
        r = json.loads(f.readline())
        if "return" in r or "error" in r: return r
f.readline(); rpc({"execute": "qmp_capabilities"})
rpc({"execute": "migrate-set-parameters", "arguments": {"max-bandwidth": 8 << 30}})
rpc({"execute": "stop"})                                   # pause vCPU for a consistent RAM image
r = rpc({"execute": "migrate", "arguments": {"uri": "exec:gzip -c > %s" % out}})
if "error" in r: print("MIGRATE_ERR", r["error"]); sys.exit(1)
st = ""
for _ in range(240):
    st = rpc({"execute": "query-migrate"}).get("return", {}).get("status", "")
    if st in ("completed", "failed", "cancelled"): break
    time.sleep(0.5)
print("MIGRATE", st)
rpc({"execute": "cont"})                                   # resume the source box (leave it live)
sys.exit(0 if st == "completed" else 2)
PY
echo "BAKED: state.gz updated (MIGRATE completed)"
