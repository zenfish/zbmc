#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
model=${1:-$repo/experiments/ilo5/renode/GxpUmac.cs}
renode=${RENODE:-$repo/renode/runtime/renode}
out=$(mktemp -d "${TMPDIR:-/tmp}/ilo5-umac-test.XXXXXX")
printf 'Evidence: %s\n' "$out"
printf 'request.Value = 0\n' > "$out/irq.py"
cat > "$out/platform.repl" <<EOF
ram: Memory.MappedMemory @ sysbus 0x1000
    size: 0x3000
irq: Python.PythonPeripheral @ sysbus 0x9000
    size: 0x1000
    filename: "$out/irq.py"
mac: Network.GxpUmac @ sysbus 0x8000
    interruptController: irq
    preinit:
        include @$model
EOF
cat > "$out/test.py" <<'PYTEST'
from System import Array, Byte
from Antmicro.Renode.Network import EthernetFrame
bus = monitor.Machine['sysbus']
mac = monitor.Machine['sysbus.mac']
# Synthetic ARP preserves an ordinary Ethernet payload without contacting a guest.
base = bytearray.fromhex('ffffffffffff3c5282000501080600010800060400013c52820005010a0002020000000000000a00020f')
for length in (42, 60, 100):
    payload = base + bytearray((i & 255 for i in range(length - len(base))))
    ok, frame = EthernetFrame.TryCreateEthernetFrame(Array[Byte](payload), True)
    assert ok
    mac.Reset()
    mac.WriteDoubleWord(0x4c, 0x1000)
    bus.WriteDoubleWord(0x1000, 0x2000)
    bus.WriteWord(0x1004, 0x8000)
    bus.WriteWord(0x1006, 1536)
    mac.ReceiveFrame(frame)
    count = bus.ReadWord(0x1006)
    assert count == max(length, 60) + 4, (length, count)
    received = bus.ReadBytes(0x2000, count)
    assert list(received[:length]) == list(payload)
    assert all(value == 0 for value in received[length:count-4])
    assert EthernetFrame.CheckCRC(received)
    assert bus.ReadWord(0x1004) == 0
    if length >= 60:
        assert list(received) == list(frame.Bytes)
print('PASS: native UMAC short-frame padding, payload, FCS, and full-frame preservation')
PYTEST
cat > "$out/run.resc" <<EOF
mach create "umac-test"
machine LoadPlatformDescription @$out/platform.repl
python "exec(open('$out/test.py').read())"
quit
EOF
timeout 45 "$renode" --disable-xwt --plain --console "$out/run.resc" > "$out/renode.log" 2>&1
cat "$out/renode.log"
grep -q '^PASS: native UMAC short-frame padding' "$out/renode.log"
