#!/usr/bin/env python3
"""Small fixtures prove warm restore rejects incompatible artifact combinations."""
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('warm', repo / 'boxes/lenovo-xcc/verify-warm.py')
warm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(warm)

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    (root / 'ckpt').mkdir()
    for name in warm.FILES:
        (root / name).write_bytes(name.encode())
    argv = root / 'ckpt/source-argv.json'
    argv.write_text(json.dumps(['qemu', '-netdev', 'tap,id=net0,ifname=ztap-xcc']))
    qemu = root / 'qemu'
    qemu.write_bytes(b'fixture-qemu')
    qemu.chmod(0o700)
    manifest = {'sha256': {captured: warm.digest(root / installed)
                           for installed, captured in warm.FILES.items()},
                'qemu_sha256': warm.digest(qemu)}
    path = root / 'ckpt/manifest.json'
    path.write_text(json.dumps(manifest))
    warm.verify(root, str(qemu))

    def rejected():
        try:
            warm.verify(root, str(qemu))
        except (OSError, ValueError, KeyError):
            return
        raise AssertionError('Incompatible checkpoint accepted')

    for file in ('ckpt/state.gz', 'ckpt/emmc.qcow2', 'kernel-shell.zImage', 'qemu'):
        target = root / file
        saved = target.read_bytes()
        target.write_bytes(b'wrong artifact')
        rejected()
        target.write_bytes(saved)
    argv.write_text(json.dumps(['qemu', '-netdev', 'user,id=net0']))
    manifest['sha256']['source-argv.json'] = warm.digest(argv)
    path.write_text(json.dumps(manifest))
    rejected()
    path.unlink()
    rejected()
    # A rejected warm bundle must not remove an existing runtime socket or launch QEMU.
    for name in ('kernel.zImage', 'emmc.qcow2'):
        (root / name).write_bytes(b'fixture')
    sentinel = root / 'serial.sock'
    sentinel.write_bytes(b'preserve existing socket')
    result = subprocess.run(['bash', str(repo / 'boxes/lenovo-xcc/boot.sh')],
        env=os.environ | {'WD': str(root), 'ZBMC_WARM': '1', 'ZBMC_QEMU': str(qemu), 'TAP': 'ztap-xcc'},
        capture_output=True, text=True)
    assert result.returncode != 0 and 'warm checkpoint rejected' in result.stderr
    assert sentinel.read_bytes() == b'preserve existing socket'
    assert not (root / 'launcher.log').exists()
    log = root / 'launcher.log'
    pid = root / 'boot.pid'
    log.write_text('preserved log')
    pid.write_text('preserved pid')
    result = subprocess.run(['bash', '-c',
        '_zbmc_resolve_ip(){ echo 127.0.0.1; }; source "$1"; ZBMC_QEMU="$2"; ZBMC_WARM=1; zbmc_boot',
        'test', str(repo / 'boxes/lenovo-xcc/zbmc.box'), str(qemu)],
        env=os.environ | {'ZBMC_DIR': str(root)}, capture_output=True, text=True)
    assert result.returncode != 0 and 'warm checkpoint rejected' in result.stderr
    assert log.read_text() == 'preserved log' and pid.read_text() == 'preserved pid'
    argv.write_text(json.dumps(['qemu', '-netdev', 'tap,id=net0,ifname=ztap-xcc']))
    manifest['sha256']['source-argv.json'] = warm.digest(argv)
    path.write_text(json.dumps(manifest))
    warm.verify(root, str(qemu))
    result = subprocess.run(['bash', str(repo / 'boxes/lenovo-xcc/boot.sh')],
        env=os.environ | {'WD': str(root), 'ZBMC_WARM': '1', 'ZBMC_QEMU': str(qemu), 'TAP': ''},
        capture_output=True, text=True)
    assert result.returncode != 0 and 'destination TAP is required' in result.stderr
    assert sentinel.read_bytes() == b'preserve existing socket'
    assert log.read_text() == 'preserved log' and pid.read_text() == 'preserved pid'

print('PASS: matched TAP checkpoint accepted; wrong disk/RAM/kernel/QEMU, SLiRP and missing manifest rejected')
