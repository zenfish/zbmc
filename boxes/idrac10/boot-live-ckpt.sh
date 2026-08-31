#!/usr/bin/env bash
# Save the currently running, READY iDRAC10 guest for an explicit --warm restore.
set -euo pipefail
cd "${WD:-$(dirname "$0")}"

W="${CKPT:-$PWD/ckpt}"
QMP="$PWD/qmp.sock"
OVL="$PWD/runtime-overlay.qcow2"
STATE="$W/state.gz"
FROZEN="$W/overlay-frozen.qcow2"
mkdir -p "$W"

[ -S "$QMP" ] || { echo "no live QMP socket at $QMP; cold-start iDRAC10 first" >&2; exit 1; }
[ -f "$OVL" ] || { echo "no live disk overlay at $OVL" >&2; exit 1; }

python3 - "$QMP" "$OVL" "$STATE" "$FROZEN" <<'PY'
import json
import os
import shutil
import socket
import sys
import time

qmp, overlay, state, frozen = sys.argv[1:]
state_tmp = state + ".tmp"
frozen_tmp = frozen + ".tmp"
for path in (state_tmp, frozen_tmp):
    try:
        os.unlink(path)
    except FileNotFoundError:
        pass

s = socket.socket(socket.AF_UNIX)
s.connect(qmp)
f = s.makefile("rw", buffering=1)
f.readline()

def rpc(command):
    f.write(json.dumps(command) + "\n")
    f.flush()
    while True:
        reply = json.loads(f.readline())
        if "event" not in reply:
            return reply

rpc({"execute": "qmp_capabilities"})
stopped = False
try:
    reply = rpc({"execute": "device_del", "arguments": {"id": "tcpnic"}})
    if "error" in reply:
        raise RuntimeError(reply["error"])
    deadline = time.time() + 15
    while time.time() < deadline:
        children = rpc({"execute": "qom-list", "arguments": {"path": "/machine/peripheral"}}).get("return", [])
        if not any(item.get("name") == "tcpnic" for item in children):
            break
        time.sleep(0.25)
    else:
        raise TimeoutError("usb-net tcpnic did not unplug")

    rpc({"execute": "migrate-set-parameters", "arguments": {"max-bandwidth": 8 << 30}})
    rpc({"execute": "stop"})
    stopped = True
    reply = rpc({"execute": "migrate", "arguments": {"uri": f"exec:gzip -c > {state_tmp}"}})
    if "error" in reply:
        raise RuntimeError(reply["error"])
    deadline = time.time() + 180
    while time.time() < deadline:
        status = rpc({"execute": "query-migrate"}).get("return", {}).get("status")
        if status == "completed":
            break
        if status in ("failed", "cancelled"):
            raise RuntimeError(f"migration {status}")
        time.sleep(0.5)
    else:
        raise TimeoutError("migration did not complete in 180 seconds")

    shutil.copy2(overlay, frozen_tmp)
    os.replace(frozen_tmp, frozen)
    os.replace(state_tmp, state)
finally:
    if stopped:
        rpc({"execute": "cont"})
PY

echo "SNAPSHOT SAVED $STATE"
ls -lh "$STATE" "$FROZEN"
