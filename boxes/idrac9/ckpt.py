#!/usr/bin/env python3
# ckpt.py — QEMU checkpoint helper via QMP for the virtual iDRAC9.
# WHAT: save/restore the FULL machine state (RAM+CPU+devices) to a file, so we snapshot the settled
#       box once (~9min boot) and resume in seconds instead of re-booting each iteration / after a crash.
# WHY : our disk is READ-ONLY squashfs; ALL mutable state lives in RAM/tmpfs, so a RAM+device
#       checkpoint captures everything and restore re-attaches the same RO disk.
# NIC : QEMU's usb-net has no migration state ("State blocked by non-migratable device usb-net").
#       So save() hot-UNPLUGS nic0 first (guest doesn't need it internally — the mesh is local unix
#       sockets; nic0 is only host ssh/redfish), snapshots, then re-plugs on the source. restore-finish()
#       re-adds nic0 after an -incoming launch so slirp-net.service reconfigures host access.
# USAGE:
#   ckpt.py save          <qmp.sock> <out.gz>   # unplug nic -> pause -> migrate-to-file -> replug+resume
#   ckpt.py restore-finish <qmp.sock>           # after `-incoming`: cont + hot-add nic0
#   ckpt.py test          <qmp.sock>            # probe: can it migrate (after unplug)?
#   ckpt.py status        <qmp.sock>
import socket, json, sys, time, os

NIC = {"driver": "usb-net", "netdev": "n1", "bus": "usb-bus.0", "id": "nic0"}   # matches run-p6.sh cold-plug bus

# With qemu-system-arm-patched (migratable usb-net, see qemu-patch/), usb-net is NOT unplugged before
# save: it migrates with the machine and is already present on restore, so host network SURVIVES the
# restore (no hot-add, no broken re-enumeration). Set QEMU_NO_UNPLUG=1 for that flow (the default when
# QEMU_BIN points at the patched binary). Unset = legacy stock-qemu flow (unplug nic0, re-add on restore).
NO_UNPLUG = os.environ.get("QEMU_NO_UNPLUG") == "1"

def connect(path):
    s = socket.socket(socket.AF_UNIX); s.connect(path)
    f = s.makefile('rw', buffering=1)
    f.readline()                                   # QMP greeting
    _rpc(f, {"execute": "qmp_capabilities"})
    return s, f

def _rpc(f, obj):
    f.write(json.dumps(obj) + "\n"); f.flush()
    while True:                                    # skip async events, return the reply
        line = f.readline()
        if not line:
            return {"error": "connection closed"}
        r = json.loads(line)
        if "return" in r or "error" in r:
            return r

def _has_nic(f):
    for d in _rpc(f, {"execute": "query-pci"}).get("return", []) or []:
        pass
    # usb-net isn't PCI; check qom-path existence instead
    r = _rpc(f, {"execute": "qom-list", "arguments": {"path": "/machine/peripheral/nic0"}})
    return "return" in r

def _wait_migrate(f, timeout=1800):
    t0 = time.time()
    while time.time() - t0 < timeout:
        r = _rpc(f, {"execute": "query-migrate"})
        st = r.get("return", {}).get("status", "?")
        if st in ("completed", "failed", "cancelled"):
            return st, r.get("return", {})
        time.sleep(0.5)
    return "timeout", {}

def _del_nic(f):
    if _has_nic(f):
        _rpc(f, {"execute": "device_del", "arguments": {"id": "nic0"}})
        for _ in range(40):                        # wait for the guest-acked removal
            if not _has_nic(f):
                break
            time.sleep(0.25)

def _add_nic(f):
    if not _has_nic(f):
        print("device_add nic0:", _rpc(f, {"execute": "device_add", "arguments": NIC}))

def save(path, out):
    s, f = connect(path)
    _rpc(f, {"execute": "migrate-set-parameters", "arguments": {"max-bandwidth": 8 << 30}})
    if not NO_UNPLUG:
        _del_nic(f)                                # legacy: drop the non-migratable NIC
    _rpc(f, {"execute": "stop"})                   # consistent point-in-time
    r = _rpc(f, {"execute": "migrate", "arguments": {"uri": "exec:gzip -c > %s" % out}})
    if "error" in r:
        print("MIGRATE-REJECTED:", r["error"]); _rpc(f, {"execute": "cont"})
        if not NO_UNPLUG: _add_nic(f)
        return 2
    st, info = _wait_migrate(f)
    _rpc(f, {"execute": "cont"})                   # resume the source so it keeps running
    if not NO_UNPLUG:
        _add_nic(f)                                # give the source its NIC back
    print("SAVE:", st, "->", out, "(NO_UNPLUG)" if NO_UNPLUG else "(unplug)")
    if st != "completed":
        print("DETAIL:", json.dumps(info)); return 1
    return 0

def restore_finish(path):
    s, f = connect(path)
    # after -incoming the VM is loaded but paused; resume it
    print("cont:", _rpc(f, {"execute": "cont"}))
    if not NO_UNPLUG:
        time.sleep(1)
        _add_nic(f)                                # legacy: hot-add nic0 (broken on npcm — net won't return)
    else:
        print("NO_UNPLUG: usb-net already in restored state; host network is live.")
    return 0

def test(path):
    s, f = connect(path)
    _rpc(f, {"execute": "migrate-set-parameters", "arguments": {"max-bandwidth": 8 << 30}})
    _del_nic(f)
    r = _rpc(f, {"execute": "migrate", "arguments": {"uri": "exec:cat > /dev/null"}})
    if "error" in r:
        print("MIGRATE-REJECTED:", r["error"]); _add_nic(f); return 2
    st, info = _wait_migrate(f, timeout=180)
    print("MIGRATE-TEST:", st, "" if st == "completed" else json.dumps(info))
    _rpc(f, {"execute": "cont"}); _add_nic(f)
    return 0 if st == "completed" else 1

def status(path):
    s, f = connect(path); print(json.dumps(_rpc(f, {"execute": "query-status"}))); return 0

if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    fn = {"save": lambda: save(sys.argv[2], sys.argv[3]),
          "restore-finish": lambda: restore_finish(sys.argv[2]),
          "test": lambda: test(sys.argv[2]),
          "status": lambda: status(sys.argv[2])}.get(cmd)
    sys.exit(fn() if fn else (print(__doc__) or 2))
