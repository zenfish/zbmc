#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
python3 - "${1:-$repo/experiments/ilo5/renode/gxp_dev.py}" <<'PYTEST'
import sys
from pathlib import Path
from types import SimpleNamespace

code = compile(Path(sys.argv[1]).read_text(), sys.argv[1], 'exec')
scope = {'self': SimpleNamespace(InfoLog=lambda message: None)}


def access(kind, offset=0, value=0):
    request = SimpleNamespace(IsInit=kind == 'init', IsRead=kind == 'read', Offset=offset, Value=value)
    scope['request'] = request
    exec(code, scope)
    return request.Value


access('init')
assert access('read', 0x3b) == 0x20, 'primary PHY strap must survive model updates'
access('write', 0x88, 0x12345678)
assert access('read', 0x88) == 0x12345678, 'preserve ordinary register writes'
access('write', 0x34, 1)
assert access('read', 0x30) == 0x01000080, 'preserve mailbox completion/link state'
print('PASS: PHY strap, write retention, mailbox completion')
PYTEST
