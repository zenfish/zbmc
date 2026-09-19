#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
python3 - "${1:-$repo/experiments/ilo5/renode/gxp_scan.py}" <<'PYTEST'
import sys
from pathlib import Path
from types import SimpleNamespace

code = compile(Path(sys.argv[1]).read_text(), 'gxp_scan.py', 'exec')
scope = {}


def access(kind, offset=0, length=2, value=0):
    request = SimpleNamespace(IsInit=kind == 'init', IsRead=kind == 'read', IsWrite=kind == 'write',
                              Offset=offset, Length=length, Value=value)
    scope['request'] = request
    exec(code, scope)
    return request.Value


access('init')
for target in (0x25, 0x26, 0x24):
    for _ in range(257):
        if access('read', 0xb8) >> 8 == target:
            break
    else:
        raise AssertionError('native GPIO startup would remain in its retry loop')
access('write', 0xb8)
assert [access('read', 0xb8) for _ in range(256)] == [i << 8 for i in range(256)]
assert access('read', 0xb8) == 0
access('write', 0x100, 4, 0x12345678)
assert access('read', 0x101, 2) == 0x3456
scope['SAMPLES'][1] = 0xa5
access('write', 0xb8)
assert access('read', 0xb8) == 0
assert access('read', 0xb8) == 0x01a5
print('PASS: native startup polling, scan restart/wrap, sample byte, ordinary storage')
PYTEST
