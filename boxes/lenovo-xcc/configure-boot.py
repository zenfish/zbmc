#!/usr/bin/env python3
"""Set native Gunicorn startup timeout in Lenovo's framed appended DTBs."""
import pathlib
import struct
import subprocess
import sys
import tempfile

HEADER = struct.Struct('<6I')
PREFIX = (0xEDFE0DD0, 0x800)
ARG = 'GUNICORN_CMD_ARGS=--timeout=1800'


def configure(source: bytes) -> bytes:
    offset = struct.unpack_from('<I', source, 0x2C)[0]
    if not 0x30 <= offset < len(source):
        raise ValueError('invalid zImage end offset')
    output = bytearray(source[:offset])
    count = 0
    with tempfile.TemporaryDirectory() as directory:
        dtb = pathlib.Path(directory) / 'boot.dtb'
        while offset + HEADER.size <= len(source):
            header = list(HEADER.unpack_from(source, offset))
            offset += HEADER.size
            if tuple(header[:2]) != PREFIX or header[3] != HEADER.size:
                raise ValueError('invalid Lenovo DTB frame')
            if header[2] == 1:
                if header[4:] != [0, 0] or offset != len(source) or count != 9:
                    raise ValueError('invalid Lenovo DTB terminator')
                output.extend(HEADER.pack(*header))
                return bytes(output)
            length = header[5]
            if header[2] != 0 or header[4] != count or not 40 <= length <= len(source) - offset:
                raise ValueError('invalid Lenovo DTB payload')
            payload = source[offset:offset + length]
            if payload[:4] != b'\xd0\x0d\xfe\xed':
                raise ValueError('missing DTB magic')
            size = struct.unpack_from('>I', payload, 4)[0]
            if not 40 <= size <= length or payload[size:] != b'@' * (length - size):
                raise ValueError('invalid DTB size or padding')
            dtb.write_bytes(payload[:size])
            args = subprocess.check_output(['fdtget', '-t', 's', str(dtb), '/chosen', 'bootargs'], text=True).strip()
            args = ' '.join([word for word in args.split() if not word.startswith('GUNICORN_CMD_ARGS=')] + [ARG])
            subprocess.run(['fdtput', '-t', 's', str(dtb), '/chosen', 'bootargs', args], check=True)
            configured = dtb.read_bytes()
            header[5] = (len(configured) + 7) & ~7
            output.extend(HEADER.pack(*header))
            output.extend(configured)
            output.extend(b'@' * (header[5] - len(configured)))
            offset += length
            count += 1
    raise ValueError('missing Lenovo DTB terminator')


if __name__ == '__main__':
    source, destination = map(pathlib.Path, sys.argv[1:])
    if source.resolve() == destination.resolve():
        raise ValueError('preserve the source kernel; choose a separate output')
    destination.write_bytes(configure(source.read_bytes()))
