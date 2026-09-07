#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
python3 - "$repo/experiments/ilo5/renode/patch_kernel.py" <<'PYTEST'
import importlib.util
import struct
import sys
import tempfile
from pathlib import Path
spec = importlib.util.spec_from_file_location('patch_kernel', sys.argv[1])
patcher = importlib.util.module_from_spec(spec)
spec.loader.exec_module(patcher)
native = {0x410185a4: 0xe92d4020, 0x410185a8: 0xe1a05000,
          0x41018600: 0xe92d4020, 0x41018604: 0xe1a05000}
assert not native.keys() & {entry[0] for entry in patcher.PATCHES}
fixture = bytearray(max(entry[0] for entry in patcher.PATCHES) - patcher.BASE + 4)
for address, expected, replacement, reason in patcher.PATCHES:
    struct.pack_into('<I', fixture, address - patcher.BASE, expected)
for address, word in native.items():
    struct.pack_into('<I', fixture, address - patcher.BASE, word)
with tempfile.TemporaryDirectory() as directory:
    source, output = Path(directory)/'source.bin', Path(directory)/'patched.bin'
    source.write_bytes(fixture)
    patcher.main(str(source), str(output))
    assert source.read_bytes() == fixture
    result = output.read_bytes()
    for address, word in native.items():
        assert struct.unpack_from('<I', result, address-patcher.BASE)[0] == word
    for address, expected, replacement, reason in patcher.PATCHES:
        assert struct.unpack_from('<I', result, address-patcher.BASE)[0] == replacement
print('PASS: boot patches apply to a copy; both native SRAM validators remain intact')
PYTEST
