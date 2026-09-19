#!/usr/bin/env python3
"""Run the actual background helper against a private-config-only fixture."""
import pathlib
import re
import subprocess
import sys
import tempfile

source_path = pathlib.Path(sys.argv[1]) if len(sys.argv) > 1 else pathlib.Path(__file__).resolve().parents[1] / 'tools/zbmc'
source = source_path.read_text()
match = re.search(r"nohup bash -c '(.*?)' bash (.*?) \\\n", source, re.S)
assert match, 'background helper not found'
assert '"$_REPO"' in match[2], 'repository argument missing'
with tempfile.TemporaryDirectory() as directory:
    root = pathlib.Path(directory)
    (root / 'zbmc.conf').write_text('PRIVATE_TEST=loaded\n')
    box = root / 'zbmc.box'
    box.write_text('''test "${PRIVATE_TEST:-}" = loaded || exit 41
zbmc_ssh() { echo up; }
_zbmc_ssh_check() { zbmc_ssh; }
zbmc_web() { echo WEB_STARTED; }
sleep() { :; }
ps() { return 0; }
''')
    result = subprocess.run(['bash', '-c', match[1], 'bash', str(box),
        '127.0.0.1', '22', '623', '443', '1', directory, 'fixture', directory],
        capture_output=True, text=True, timeout=3)
    assert result.returncode == 0, result.stderr
    assert result.stdout.strip() == 'WEB_STARTED', result.stdout
print('background Web private configuration: PASS')
