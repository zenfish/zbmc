#!/usr/bin/env python3
"""Probe XCC OEM authorization without sending valid mutating payloads."""

from __future__ import annotations

import argparse
import json
import os
import time
from datetime import datetime, timezone

from zipmi.core import Session


PROBES = [
    ("firmware-version", 0x3A, 0x00, "", "safe baseline"),
    ("native-nm-get", 0x3A, 0xC7, "", "Admin baseline"),
    ("osa-get-bmc-address", 0x2E, 0xCC, "5e2b000642", "safe inner-Admin route"),
    ("osa-reset-default-short", 0x2E, 0xCC, "5e2b000a01", "short before reset body"),
    ("osa-graceful-reset-short", 0x2E, 0xCC, "5e2b000643", "short before reset body"),
    ("osa-set-guid-short", 0x2E, 0xCC, "5e2b000640", "short before GUID body"),
    ("osa-set-bmc-address-short", 0x2E, 0xCC, "5e2b000641", "short before address body"),
    ("osa-power-manager-short", 0x2E, 0xCC, "5e2b000646", "short before control body"),
    ("osa-power-limit-short", 0x2E, 0xCC, "5e2b000649", "short before power-limit body"),
    ("osa-sensor-test-short", 0x2E, 0xCC, "5e2b000440", "short before test body"),
    ("osa-nic-teaming-short", 0x2E, 0xCC, "5e2b000c01", "short before network body"),
    ("osa-ipv6-set-short", 0x2E, 0xCC, "5e2b000c09", "short before network body"),
    ("osa-shared-lom-short", 0x2E, 0xCC, "5e2b000c07", "short before LOM body"),
    ("osa-memory-check-short", 0x2E, 0xCC, "5e2b001000", "short before control body"),
    ("nmi-reset-short", 0x3A, 0x38, "", "short before NMI/reset body"),
    ("i2c-master-short", 0x3A, 0x94, "", "short before bus/address body"),
    ("i2c-test-short", 0x3A, 0x09, "ff", "malformed bus-test body"),
    ("pcie-i2c-short", 0x3A, 0x2B, "ff00", "short before bus transaction"),
    ("datastore-open-short", 0x2E, 0x90, "664a0001", "short before datastore body"),
    ("datastore-write-short", 0x2E, 0x90, "664a0003", "short before datastore body"),
    ("tklm-short", 0x2E, 0x97, "664a00", "below TKLM minimum length"),
    ("vpd-write-short", 0x3A, 0x0C, "", "below VPD minimum length"),
    ("syncrep-op-short", 0x3A, 0x59, "", "below replication minimum length"),
    ("syncrep-init-short", 0x3A, 0x5A, "", "below replication minimum length"),
    ("bmu-credential-get-lan", 0x3A, 0x7B, "", "channel-gate check"),
    ("physical-presence-config-lan", 0x3A, 0x7C, "", "channel-gate check"),
    ("physical-presence-state-lan", 0x3A, 0x7D, "", "channel-gate check"),
]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host")
    parser.add_argument("--user")
    parser.add_argument("--privilege", choices=("user", "admin"), default="user")
    parser.add_argument("--password-env", default="IPMI_PASSWORD")
    parser.add_argument("--output")
    parser.add_argument("--list", action="store_true")
    args = parser.parse_args()
    if args.list:
        print(json.dumps([{"name": p[0], "netfn": p[1], "cmd": p[2], "data": p[3], "guard": p[4]} for p in PROBES], indent=2))
        return 0
    if not args.host or not args.user:
        parser.error("--host and --user are required unless --list is used")
    password = os.environ.get(args.password_env)
    if password is None:
        parser.error(f"{args.password_env} is not set")

    privilege = 2 if args.privilege == "user" else 4
    session = None
    errors = []
    for attempt in range(1, 4):
        candidate = Session(args.host, args.user, password, priv=privilege,
                            timeout=30, lanplus=True, cipher_suite=17)
        candidate.transport.retries = 1
        try:
            candidate.activate()
            session = candidate
            break
        except Exception as exc:
            candidate.close()
            errors.append(f"attempt {attempt}: {exc}")
    if session is None:
        raise SystemExit("session activation failed: " + "; ".join(errors))

    results = []
    try:
        for name, netfn, cmd, data_hex, guard in PROBES:
            started = time.monotonic()
            try:
                cc, data = session.send_raw(netfn, cmd, bytes.fromhex(data_hex))
                results.append({"name": name, "netfn": netfn, "cmd": cmd,
                                "request": data_hex, "completionCode": cc,
                                "response": data.hex(), "guard": guard,
                                "elapsedMs": round((time.monotonic() - started) * 1000)})
            except Exception as exc:
                results.append({"name": name, "netfn": netfn, "cmd": cmd,
                                "request": data_hex, "error": str(exc), "guard": guard,
                                "elapsedMs": round((time.monotonic() - started) * 1000)})
    finally:
        session.close()

    report = {
        "schema": "zbmc.lenovo-xcc.oem-authorization-audit.v1",
        "generated": datetime.now(timezone.utc).isoformat(),
        "host": args.host,
        "user": args.user,
        "requestedPrivilege": privilege,
        "grantedPrivilege": session.granted_priv,
        "cipherSuite": 17,
        "activationErrors": errors,
        "results": results,
    }
    rendered = json.dumps(report, indent=2) + "\n"
    if args.output:
        with open(args.output, "w", encoding="utf-8") as stream:
            stream.write(rendered)
    print(rendered, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
