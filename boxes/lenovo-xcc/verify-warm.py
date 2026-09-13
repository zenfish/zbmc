#!/usr/bin/env python3
"""Reject mismatched or pre-TAP Lenovo migration checkpoints before launch."""
import hashlib
import json
from pathlib import Path
import shutil
import sys


FILES = {
    'ckpt/state.gz': 'state.gz',
    'ckpt/emmc.qcow2': 'emmc.qcow2',
    'ckpt/source-argv.json': 'source-argv.json',
    'kernel-shell.zImage': 'kernel-runtime.zImage',
    'xcc.dtb': 'xcc.dtb',
    'sram.bin': 'sram.bin',
    'ptables.bin': 'ptables.bin',
}


def digest(path):
    with open(path, 'rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def verify(runtime, qemu):
    runtime = Path(runtime)
    manifest = json.loads((runtime / 'ckpt/manifest.json').read_text())
    for installed, captured in FILES.items():
        if digest(runtime / installed) != manifest['sha256'][captured]:
            raise ValueError('checkpoint mismatch: ' + installed)
    executable = shutil.which(qemu)
    if executable is None or digest(executable) != manifest['qemu_sha256']:
        raise ValueError('checkpoint QEMU binary mismatch')
    argv = json.loads((runtime / 'ckpt/source-argv.json').read_text())
    networks = [argv[i + 1] for i, arg in enumerate(argv[:-1]) if arg == '-netdev']
    if not any(net.startswith('tap,') and 'id=net0' in net.split(',') for net in networks):
        raise ValueError('checkpoint does not contain the TAP management NIC')


if __name__ == '__main__':
    try:
        verify(*sys.argv[1:])
    except (OSError, ValueError, KeyError, TypeError) as error:
        sys.exit('Lenovo warm checkpoint rejected: ' + str(error))
    print('Matched Lenovo TAP checkpoint verified')
