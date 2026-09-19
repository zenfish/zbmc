#!/usr/bin/env python3
"""A lost TAP ping must fail readiness even when all application probes pass."""
import json
import os
from pathlib import Path
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[1]
common = r'''
set -u
source "$REPO/tools/zbmc-runlib"
ZBMC_RUN_ID=test ZBMC_RUN_START_EPOCH=0 ZBMC_IP=192.0.2.1
ZBMC_REQUIRED_SERVICES='ssh ipmi redfish webui console'
ZBMC_STABILITY_SECONDS=3 ZBMC_HEALTH_INTERVAL=0
ZBMC_CONSOLE_LOG="$ZBMC_RUN_DIR/console.log"
printf 'fixture console\n' >"$ZBMC_CONSOLE_LOG"
_zr_probe_service(){ printf 'ok|fixture|passed\n' >"$2"; }
_zr_service_disabled(){ return 1; }
_zr_service_should_probe(){ return 0; }
_zr_event(){ :; }; _zr_timing(){ :; }; _zr_archive_logs(){ :; }
_zr_qmp_snapshot(){ :; }; _zr_snapshot(){ :; }; _zr_capture_stop(){ :; }
_zr_termination(){ :; }; _zr_expected(){ echo fixture; }
_zr_result(){ echo "$1" >"$ZBMC_RUN_DIR/result"; }
sleep(){ :; }
'''

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    for mode, ping_rc, expected in [('tap', '0', 'ready'), ('tap', '1', 'degraded'), ('user', '1', 'ready')]:
        run = root / f'{mode}-{ping_rc}'
        run.mkdir()
        script = common + r'''
ps(){ [ ! -f "$ZBMC_RUN_DIR/health.json" ]; }
ping(){ return "$PING_RC"; }
_zr_health_watch 999999
'''
        subprocess.run(['bash', '-c', script], check=True, env=os.environ | {
            'REPO': str(repo), 'ZBMC_RUN_DIR': str(run), 'ZBMC_NETWORK_MODE': mode, 'PING_RC': ping_rc})
        health = json.loads((run / 'health.json').read_text())
        assert health['state'] == expected, health
        assert ('icmp' in health['required']) == (mode == 'tap'), health
        if mode == 'tap':
            assert health['checks']['icmp']['state'] == ('ok' if ping_rc == '0' else 'fail'), health

    run = root / 'startup'
    run.mkdir()
    (run / 'clock').write_text('0')
    script = common + r'''
ps(){ return 0; }
_zr_now(){ local n; n=$(<"$ZBMC_RUN_DIR/clock"); n=$((n+1)); echo "$n" >"$ZBMC_RUN_DIR/clock"; echo "$n"; }
ping(){ if [ -f "$ZBMC_RUN_DIR/pinged" ]; then return 1; fi; touch "$ZBMC_RUN_DIR/pinged"; return 0; }
_zr_health_watch(){ :; }
_zr_wait_ready 999999 20
'''
    result = subprocess.run(['bash', '-c', script], env=os.environ | {
        'REPO': str(repo), 'ZBMC_RUN_DIR': str(run), 'ZBMC_NETWORK_MODE': 'tap'}, capture_output=True, text=True, timeout=10)
    assert result.returncode == 1, (result.returncode, result.stdout, result.stderr)
    assert (run / 'result').read_text().strip() == 'timeout'

print('PASS: TAP health requires current ICMP; lost ping prevents startup READY; user networking unchanged')
