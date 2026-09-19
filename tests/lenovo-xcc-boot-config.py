#!/usr/bin/env python3
"""Check framed DTB boot configuration without requiring firmware artifacts."""
import pathlib
import runpy
import struct
import subprocess
import tempfile

repo = pathlib.Path(__file__).resolve().parents[1]
module = runpy.run_path(str(repo / 'boxes/lenovo-xcc/configure-boot.py'))
configure, header = module['configure'], module['HEADER']
with tempfile.TemporaryDirectory() as directory:
    root = pathlib.Path(directory)
    original = root / 'original.dtb'
    subprocess.run(['dtc', '-q', '-I', 'dts', '-O', 'dtb', '-o', str(original)],
                   input=b'/dts-v1/; / { model = "preserve-me"; chosen { bootargs = "console=ttyS4,115200"; }; };', check=True)
    dtb = original.read_bytes()
    length = (len(dtb) + 7) & ~7
    source = bytearray(64)
    struct.pack_into('<I', source, 0x2C, 64)
    for index in range(9):
        source += header.pack(*module['PREFIX'], 0, 24, index, length)
        source += dtb + b'@' * (length - len(dtb))
    source += header.pack(*module['PREFIX'], 1, 24, 0, 0)
    result = configure(bytes(source))
    assert result[:64] == source[:64]
    assert configure(result) == result
    offset = 64
    for index in range(9):
        fields = header.unpack_from(result, offset)
        assert fields[4] == index
        length = fields[5]
        offset += 24
        modified = root / 'modified.dtb'
        modified.write_bytes(result[offset:offset + length])
        def tree(path):
            return subprocess.check_output(['dtc', '-q', '-s', '-I', 'dtb', '-O', 'dts', str(path)])
        assert tree(modified) == tree(original).replace(b'console=ttyS4,115200', b'console=ttyS4,115200 ' + module['ARG'].encode())
        offset += length
    assert offset + 24 == len(result)
    try:
        configure(bytes(source[:-1]))
    except ValueError:
        pass
    else:
        raise AssertionError('truncated frame accepted')
print('Lenovo appended DTB boot configuration: PASS')
