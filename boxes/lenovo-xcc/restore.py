#!/usr/bin/env python3
"""Resume a matched Lenovo QEMU checkpoint; report only verified running state."""
import json
import shlex
import socket
import sys
import time


def restore(qmp, state):
    deadline = time.monotonic() + 120
    with socket.socket(socket.AF_UNIX) as sock:
        sock.settimeout(10)
        while True:
            try:
                sock.connect(qmp)
                break
            except (FileNotFoundError, ConnectionRefusedError):
                if time.monotonic() >= deadline:
                    raise TimeoutError("QMP socket did not become available")
                time.sleep(0.25)
        with sock.makefile("rwb") as stream:
            json.loads(stream.readline())

            def rpc(command, arguments=None):
                request = {"execute": command, "id": command}
                if arguments is not None:
                    request["arguments"] = arguments
                stream.write(json.dumps(request).encode() + b"\n")
                stream.flush()
                while True:
                    reply = json.loads(stream.readline())
                    if reply.get("id") == command:
                        if "error" in reply:
                            raise RuntimeError(reply["error"])
                        return reply["return"]

            rpc("qmp_capabilities")
            rpc("migrate-incoming", {"uri": "exec:gzip -dc " + shlex.quote(state)})
            while time.monotonic() < deadline:
                result = rpc("query-migrate")
                if result.get("status") == "completed":
                    break
                if result.get("status") in ("failed", "cancelled"):
                    raise RuntimeError(result)
                time.sleep(0.25)
            else:
                raise TimeoutError("Incoming migration did not complete")
            rpc("cont")
            if not rpc("query-status").get("running"):
                raise RuntimeError("Restored guest did not resume")
    print("XCC_WARM_RESTORE_RUNNING", flush=True)


if __name__ == "__main__":
    restore(*sys.argv[1:])
