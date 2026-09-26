#!/usr/bin/env python3
"""Exercise only 22 statically reviewed four-byte iRMC S6 reads."""
from __future__ import annotations

import argparse
import json
import os
import time
from datetime import datetime, timezone

from zipmi.core import Session


PROBES = (
    ("01", "15", "last-power-on-reason"),
    ("01", "16", "next-or-last-power-off-reason"),
    ("01", "18", "runtime-power-field"),
    ("01", "1d", "power-off-inhibit-state"),
    ("02", "08", "host-agent-connection-state"),
    ("e0", "00", "configuration-space-status"),
    ("f1", "21", "interrupt-enable-bank-0"),
    ("f1", "22", "interrupt-status-bank-0"),
    ("f1", "25", "interrupt-enable-bank-1"),
    ("f1", "26", "interrupt-status-bank-1"),
    ("f1", "29", "interrupt-enable-bank-2"),
    ("f1", "2a", "interrupt-status-bank-2"),
    ("f1", "2d", "interrupt-enable-bank-3"),
    ("f1", "2e", "interrupt-status-bank-3"),
    ("f1", "50", "pmb-object-counts"),
    ("f5", "4a", "f5-4a-read"),
    ("f5", "4d", "f5-4d-read"),
    ("f5", "a3", "f5-a3-read"),
    ("f5", "b1", "f5-b1-read"),
    ("f5", "b3", "f5-b3-read"),
    ("f5", "b4", "f5-b4-read"),
    ("f5", "fe", "f5-fe-read"),
)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host")
    parser.add_argument("--user")
    parser.add_argument("--password-env", default="IPMI_PASSWORD")
    parser.add_argument("--run-id")
    parser.add_argument("--output")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()
    if args.list:
        print(json.dumps([{"name": name, "netfn": "2e", "cmd": cmd,
                           "request": "802800" + selector}
                          for cmd, selector, name in PROBES], indent=2))
        return 0
    if not args.host or not args.user or not args.run_id or not args.output:
        parser.error("--host, --user, --run-id, and --output are required")
    password = os.environ.get(args.password_env)
    if password is None:
        parser.error(f"{args.password_env} is not set")

    session = Session(args.host, args.user, password, priv=4,
                      timeout=30, lanplus=True, cipher_suite=17)
    session.transport.retries = 1
    try:
        session.activate()
        results = []
        for cmd, selector, name in PROBES:
            payload = "802800" + selector
            started = time.monotonic()
            try:
                cc, response = session.send_raw(0x2E, int(cmd, 16), bytes.fromhex(payload))
                results.append({"name": name, "netfn": "2e", "cmd": cmd,
                                "request": payload, "completionCode": cc,
                                "response": response.hex(),
                                "elapsedMs": round((time.monotonic() - started) * 1000)})
            except Exception as exc:
                results.append({"name": name, "netfn": "2e", "cmd": cmd,
                                "request": payload, "error": str(exc),
                                "elapsedMs": round((time.monotonic() - started) * 1000)})
        report = {"schema": "zbmc.irmc-s6.safe-oem-probes.v1",
                  "generated": datetime.now(timezone.utc).isoformat(),
                  "runId": args.run_id, "host": args.host, "user": args.user,
                  "grantedPrivilege": session.granted_priv, "cipherSuite": 17,
                  "results": results}
    finally:
        session.close()
    with open(args.output, "w") as stream:
        json.dump(report, stream, indent=2)
        stream.write("\n")
    print(json.dumps(report, indent=2))
    return 0 if all("completionCode" in row for row in results) else 1


if __name__ == "__main__":
    raise SystemExit(main())
