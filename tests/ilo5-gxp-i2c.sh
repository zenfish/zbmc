#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
python3 - "$repo/experiments/ilo5/renode" <<'PYTEST'
import sys
from pathlib import Path
sys.path.insert(0, str(Path(sys.argv[1]).resolve()))
from gxp_i2c import GxpI2C

levels = []
bus = GxpI2C(levels.append)
base = 0x2200
for engine in range(10):
    assert bus.read(0x2008 + engine * 256, 1) == 0x33
for value in (0xb0, 0x30, 0x20, 0x3c):
    bus.write(base + 8, 1, value)
    assert bus.read(base + 8, 1) == (value & ~3) | ((value >> 4) & 3)
# Vendor Linux initialization must leave no pending event.
for offset, value in ((0xc, 20), (0xd, 0x32), (0xe, 10), (0xf, 0),
                      (9, 0), (0xa, 0), (6, 0xf0), (4, 0x80), (1, 0), (0xb, 0)):
    bus.write(base + offset, 1, value)
assert bus.read(0xf8, 4) == 0 and levels == [False]
# Native split-byte START: high byte stages address, low byte executes.
bus.write(base + 5, 1, 0xa0)
assert bus.read(0xf8, 4) == 0
bus.write(base + 4, 1, 0x81)
assert bus.read(base, 1) & 0x98 == 0x88 and bus.read(base + 1, 1) == 0x10
assert bus.read(0xf8, 4) == 4 and not levels[-1]
bus.write(0xfc, 4, 4)
assert levels[-1]
bus.write(base + 4, 1, 0x82)
assert bus.read(0xf8, 4) == 0 and not levels[-1]
# Halfword commands: set internal pointer, page-write across page end, STOP.
bus.write(base + 4, 2, 0xa001)
for byte in (6, 0x11, 0x22, 0x33):
    bus.write(base + 4, 2, (byte << 8) | 0x80)
    assert bus.read(base, 1) & 8
bus.write(base + 4, 1, 0x82)
assert bus.eeprom[6:8] == bytearray([0x11, 0x22])
assert bus.eeprom[0] == 0x33 and bus.eeprom[8] == 0xff
# Random read uses a pointer write followed by repeated START read.
bus.write(base + 4, 2, 0xa001)
bus.write(base + 4, 2, 0x0680)
bus.write(base + 4, 2, 0xa085)
for command, expected in ((0x8c, 0x11), (0x8c, 0x22), (0x84, 0xff)):
    bus.write(base + 4, 1, command)
    assert bus.read(base + 2, 1) == expected
bus.write(base + 4, 1, 0x82)
assert bus.pointer == 9
bus.write(base + 4, 2, 0xa005)
bus.write(base + 4, 1, 0x84)
assert bus.read(base + 2, 1) == 0xff and bus.pointer == 10
bus.write(base + 4, 1, 0x82)
# Sequential reads wrap at byte255; STOP clears the event even without bit7.
bus.write(base + 4, 2, 0xa001)
bus.write(base + 4, 2, 0xff80)
bus.write(base + 4, 2, 0xa085)
bus.write(base + 4, 1, 0x8c)
assert bus.read(base + 2, 1) == 0xff and bus.pointer == 0
bus.write(base + 4, 1, 0x84)
assert bus.read(base + 2, 1) == 0x33 and bus.pointer == 1
bus.write(base + 4, 1, 2)
assert bus.read(0xf8, 4) == 0 and not levels[-1]
# Absent device and a different engine complete with NACK, never fixture data.
for engine, address in ((2, 0x54), (1, 0x50)):
    target = 0x2000 + engine * 256
    bus.write(target + 4, 2, (address << 9) | 1)
    assert not bus.read(target, 1) & 8
    assert bus.read(0xf8, 4) == 1 << engine
    assert levels[-1] == (engine == 2)
    bus.write(target + 4, 1, 0x82)
assert not levels[-1]
# Explicit zero-clear and enable masking both lower IRQ without a false completion.
bus.write(base + 4, 2, 0xa001)
bus.write(0xfc, 1, 0)
assert not levels[-1] and bus.read(0xf8, 4) == 4
bus.write(0xfc, 1, 4)
assert levels[-1]
bus.write(base + 1, 1, 0)
assert not levels[-1] and not bus.read(base, 1) & 0x80
# Native setup can configure advanced/slave features without external traffic.
bus.write(base + 4, 1, 0x82)
bus.write(base + 0xa, 1, 0xff)
bus.write(base + 6, 1, 0x69)
assert bus.read(base + 0xa, 1) == 0xff and bus.read(base + 6, 1) == 0x69
assert bus.read(0xf8, 4) == 0
# Native write9: one pointer byte plus an eight-byte page, count reads become progress.
for index, byte in enumerate([0x20] + list(range(8))):
    bus.write(base + 0x20 + index, 1, byte)
bus.write(base + 0x62, 1, 9)
bus.write(base + 0x63, 1, 0)
bus.write(base + 0x61, 1, 0xa1)
assert bus.read(base + 0x60, 1) == 2
assert bus.read(base + 0x62, 2) == 9
assert bus.eeprom[0x20:0x28] == bytearray(range(8))
assert bus.read(base + 1, 1) == 0 and bus.read(0xf8, 4) == 4 and levels[-1]
bus.write(base + 0x60, 1, 2)
assert bus.read(0xf8, 4) == 0 and not levels[-1]
# Native read64: reads do not advance the aperture; each chain ACK supplies next16.
bus.write(base + 0x20, 1, 0x20)
bus.write(base + 0x62, 1, 1)
bus.write(base + 0x63, 1, 64)
bus.write(base + 0x61, 1, 0xa1)
received = bytearray()
for progress in (16, 32, 48, 64):
    assert bus.read(base + 0x62, 1) == 1
    assert bus.read(base + 0x63, 1) == progress
    assert bus.read(base + 0x60, 1) == (0x82 if progress == 64 else 0x90)
    assert bus.read(0xf8, 4) == 4 and bus.read(base + 1, 1) == 0
    before = bus.read(base + 0x20, 4)
    assert bus.read(base + 0x20, 4) == before
    for index in range(0, 16, 4):
        word = bus.read(base + 0x20 + index, 4)
        received.extend((word >> (8 * n)) & 0xff for n in range(4))
    bus.write(base + 0x60, 1, 2 if progress == 64 else 0x10)
assert received == bus.eeprom[0x20:0x60]
assert bus.pointer == 0x60 and not levels[-1]
# Masking IRQ keeps status; zero-read BTE writes still complete. Absent address NACK.
bus.write(base + 0x62, 1, 1)
bus.write(base + 0x63, 1, 0)
bus.write(base + 0x20, 1, 0)
bus.write(base + 0x61, 1, 0xa9)
assert bus.read(base + 0x60, 1) & 8
assert bus.read(base + 0x62, 2) == 0 and bus.read(0xf8, 4) == 4
bus.write(0xfc, 4, 0)
assert not levels[-1] and bus.read(0xf8, 4) == 4
bus.write(base + 0x60, 1, 0x0a)
assert bus.read(0xf8, 4) == 0 and bus.read(base + 0x60, 1) == 0
# Continuation and unknown status masks remain explicit, without fake completion.
for offset, value in ((0x60, 1), (0x71, 1)):
    try:
        bus.write(base + offset, 1, value)
    except NotImplementedError:
        pass
    else:
        raise AssertionError('unsupported transfer must not silently complete')
bus.write(base + 0x62, 1, 1)
bus.write(base + 0x63, 1, 0x80)
try:
    bus.write(base + 0x61, 1, 0xa1)
except NotImplementedError:
    pass
else:
    raise AssertionError('128-byte continuation must remain unsupported')
print('PASS: basic I2C, native BTE write9/read64, data/page/pointer, counters, ACK/NACK, IRQ')

# Native recovery must abort pending bus work without erasing EEPROM contents.
bus = GxpI2C(levels.append)
bus.write(0xfc,4,4)
bus.eeprom[7]=0x5a
bus.write(base+4,2,0xa001)
assert levels[-1] and bus.read(base,1)==0x88
bus.write(base+8,1,0xb0)
assert not levels[-1] and bus.read(base+1,1)==0 and not bus.active[2]
bus.write(base+8,1,0x30)
assert bus.read(base+8,1)==0x33 and bus.eeprom[7]==0x5a
bus.write(base+4,2,0xa001)
assert bus.read(base,1)==0x88
print('PASS: native master-status bit7 and controller reset abort')

PYTEST
