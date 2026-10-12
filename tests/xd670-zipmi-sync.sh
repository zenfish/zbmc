#!/usr/bin/env bash
# z-artifact: 4c16731a-2d3c-4c63-9e68-e48be88431ef
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
manifest="$repo/boxes/megarac-hpe/oem-ipmi-sync.json"

python3 - "$repo" "$manifest" "${ZIPMI_ROOT:-}" <<'PY'
import csv
import hashlib
import json
from pathlib import Path
import subprocess
import sys

repo = Path(sys.argv[1])
manifest_path = Path(sys.argv[2])
zipmi_arg = sys.argv[3]
manifest = json.loads(manifest_path.read_text())

expected = {
    "registrationCount": 143,
    "uniqueAddressCount": 142,
    "effectiveCommandCount": 141,
    "shadowedAddress": "0x32/0x2c",
    "winningHandler": "AMIYAFUStateless",
    "shadowedHandler": "AMIOemSetRedisDB",
    "disabledFeature": "SUPPORT_HPM_IFC",
}
for key, value in expected.items():
    assert manifest[key] == value, (key, manifest[key], value)

documents = [
    repo / "boxes/megarac-hpe/IPMI.html",
    repo / "boxes/megarac-hpe/index.html",
    repo / "docs/oem-ipmi-coverage-audit.html",
]
combined = "\n".join(path.read_text() for path in documents)
for value in (
    manifest["firmwareSha256"], manifest["pristineRootfsSha256"],
    manifest["catalogSha256"], "143 registrations", "142 unique",
    "141 effective", manifest["shadowedAddress"], manifest["winningHandler"],
    manifest["shadowedHandler"], manifest["disabledFeature"],
):
    assert str(value) in combined, value

if zipmi_arg:
    zipmi = Path(zipmi_arg).resolve()
    pinned = manifest["zipmiCommit"]
    subprocess.run(
        ["git", "merge-base", "--is-ancestor", pinned, "HEAD"],
        cwd=zipmi, check=True,
    )
    catalog = zipmi / manifest["catalogPath"]
    assert hashlib.sha256(catalog.read_bytes()).hexdigest() == manifest["catalogSha256"]
    rows = list(csv.DictReader(catalog.open(newline="")))
    assert len(rows) == manifest["registrationCount"]
    addresses = {(row["wire_netfn"], row["command"]) for row in rows}
    assert len(addresses) == manifest["uniqueAddressCount"]
    inactive = [row for row in rows if row["active_if_enabled"].startswith("no;")]
    assert len(addresses) - sum("feature gate absent" in row["active_if_enabled"] for row in inactive) == manifest["effectiveCommandCount"]

print("XD670 zBMC/zipmi synchronization: PASS")
PY
