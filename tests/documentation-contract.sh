#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)

python3 - "$repo" <<'PY'
import pathlib
import re
import sys

root = pathlib.Path(sys.argv[1])
documents = [root / "README.md", root / "GETTING-STARTED.md", root / "SECURITY.md"]
missing = []
for document in documents:
    text = document.read_text(encoding="utf-8")
    for target in re.findall(r"\[[^]]+\]\(([^)]+)\)", text):
        if "://" in target or target.startswith("#"):
            continue
        path = (document.parent / target.split("#", 1)[0]).resolve()
        if not path.exists():
            missing.append(f"{document.relative_to(root)} -> {target}")
if missing:
    raise SystemExit("missing current-document links:\n" + "\n".join(missing))
PY

grep -Fq 'sudo ./tools/zbmc openbmc start' "$repo/README.md"
grep -Fq 'sudo ./tools/zbmc openbmc start' "$repo/GETTING-STARTED.md"
! grep -Eq '(^|`)sudo zbmc openbmc start' "$repo/README.md" "$repo/GETTING-STARTED.md"
grep -Fq '`idrac10` is cold-only' "$repo/GETTING-STARTED.md"
grep -Fq 'Docker packages exact QEMU builds' "$repo/SECURITY.md"

echo 'current documentation contract: PASS'
