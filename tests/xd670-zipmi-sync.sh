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
    "operationContractsPath": "zipmi/data/sources/hpe-xd670-operation-contracts.json",
    "operationContractsSha256": "b0993ab8149b7efe5c91bc44b5080121c6755f08a8fda5f4320013c6aa2a4384",
    "selectorAcceptanceSha256": "62f98e37961e560581322a32ec53269bc5c8d63bce4c61e7bf0dd5be7c3b3859",
    "implementationContractCount": 141,
    "targetOverlayCount": 141,
    "closedCoreRequestPathCount": 55,
    "provenNormalizedWireContractCount": 25,
    "selectorAnalysisCount": 30,
    "selectorDomainsKnown": 9,
    "selectorDomainsConditional": 3,
    "selectorDomainsUnresolved": 18,
    "globalSemanticOperationCount": None,
    "reviewedRunnableRoutes": 4,
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
    "141 effective", "141 exact implementation contracts", "141 target overlays",
    "55 core request paths", "25 normalized YAFU", "nine known, three conditional, and 18 unresolved",
    "no global semantic-operation count", "only four reviewed read-only routes",
    "hpe-xd670-operation-contracts.json",
    manifest["shadowedAddress"], manifest["winningHandler"],
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
    operations_path = zipmi / manifest["operationContractsPath"]
    assert hashlib.sha256(operations_path.read_bytes()).hexdigest() == manifest["operationContractsSha256"]
    operations = json.loads(operations_path.read_text())
    assert operations["schema"] == "zipmi.hpe-xd670.contract-evidence.v2"
    counts = operations["counts"]
    assert counts["implementation_contracts"] == manifest["implementationContractCount"]
    assert counts["effective_target_command_overlays"] == manifest["targetOverlayCount"]
    assert counts["closed_core_request_paths"] == manifest["closedCoreRequestPathCount"]
    assert counts["proven_normalized_wire_contracts"] == manifest["provenNormalizedWireContractCount"]
    assert counts["selector_analyses"] == manifest["selectorAnalysisCount"]
    assert counts["selector_domains_known"] == manifest["selectorDomainsKnown"]
    assert counts["selector_domains_conditional"] == manifest["selectorDomainsConditional"]
    assert counts["selector_domains_unresolved"] == manifest["selectorDomainsUnresolved"]
    assert counts["reviewed_live_contracts"] == manifest["reviewedRunnableRoutes"]
    assert operations["denominator_policy"]["global_semantic_operation_count"] == manifest["globalSemanticOperationCount"]
    assert "operations" not in operations
    acceptance = operations["inputs"]["xd670-selector-acceptance.json"]
    assert acceptance["sha256"] == manifest["selectorAcceptanceSha256"]
    assert len(operations["implementation_contracts"]) == manifest["implementationContractCount"]
    assert len(operations["target_command_overlays"]) == manifest["targetOverlayCount"]
    assert len(operations["closed_core_request_paths"]) == manifest["closedCoreRequestPathCount"]
    assert len(operations["normalized_wire_contracts"]) == manifest["provenNormalizedWireContractCount"]
    assert len(operations["selector_analyses"]) == manifest["selectorAnalysisCount"]

print("XD670 zBMC/zipmi synchronization: PASS")
PY
