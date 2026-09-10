#!/usr/bin/env python3
"""A completed migration must also resume before emitting readiness."""
import json
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading

helper = Path(__file__).resolve().parents[1] / "boxes/lenovo-xcc/restore.py"
for running in (True, False):
    with tempfile.TemporaryDirectory() as directory:
        path = str(Path(directory) / "qmp.sock")
        server = socket.socket(socket.AF_UNIX)
        server.bind(path)
        server.listen(1)
        requests = []

        def respond():
            with server, server.accept()[0] as client, client.makefile("rwb") as stream:
                stream.write(b'{"QMP":{}}\n')
                stream.flush()
                for line in stream:
                    request = json.loads(line)
                    command = request["execute"]
                    requests.append(command)
                    result = {}
                    if command == "query-migrate":
                        result = {"status": "completed"}
                    if command == "query-status":
                        result = {"running": running}
                    stream.write(json.dumps({"return": result, "id": request["id"]}).encode() + b"\n")
                    stream.flush()

        thread = threading.Thread(target=respond, daemon=True)
        thread.start()
        result = subprocess.run([sys.executable, str(helper), path, "state.gz"],
                                capture_output=True, text=True, timeout=10)
        thread.join(2)
        assert not thread.is_alive()
        assert (result.returncode == 0) == running, result.stderr
        assert ("XCC_WARM_RESTORE_RUNNING" in result.stdout) == running
        assert requests == ["qmp_capabilities", "migrate-incoming", "query-migrate", "cont", "query-status"]
print("Lenovo restore readiness checks passed")
