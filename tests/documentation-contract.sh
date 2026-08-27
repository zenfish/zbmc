#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)

python3 - "$repo" <<'PY'
from html.parser import HTMLParser
import pathlib
import re
import subprocess
import sys

root = pathlib.Path(sys.argv[1])
documents = [root / path for path in subprocess.check_output(
    ["git", "ls-files", "--cached", "--others", "--exclude-standard", "--", "*.md", "*.html"],
    cwd=root,
    text=True,
).splitlines()]
missing = []

class HTMLLinks(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []

    def handle_starttag(self, _tag, attrs):
        self.links.extend(value for key, value in attrs if key in ("href", "src") and value)

for document in documents:
    text = document.read_text(encoding="utf-8")
    if document.suffix == ".md":
        targets = re.findall(r"(?<!!)\[[^]]*\]\(([^) ]+)(?: [^)]+)?\)", text)
    else:
        parser = HTMLLinks()
        parser.feed(text)
        targets = parser.links
    for target in targets:
        if re.match(r"^[A-Za-z][\w+.-]*:", target) or target.startswith(("#", "//")):
            continue
        relative = target.split("#", 1)[0].split("?", 1)[0]
        if not relative:
            continue
        path = (document.parent / relative).resolve()
        if not path.is_relative_to(root):
            continue
        if not path.exists():
            missing.append(f"{document.relative_to(root)} -> {target}")
if missing:
    raise SystemExit("missing documentation links:\n" + "\n".join(missing))
PY

"$repo/tools/sync-docs" --check

grep -Fq 'sudo ./tools/zbmc openbmc start' "$repo/README.md"
grep -Fq 'sudo ./tools/zbmc openbmc start' "$repo/GETTING-STARTED.md"
! grep -Eq '(^|`)sudo zbmc openbmc start' "$repo/README.md" "$repo/GETTING-STARTED.md"
grep -Fq '`idrac10` is cold-only' "$repo/GETTING-STARTED.md"
grep -Fq 'Docker packages exact QEMU builds' "$repo/SECURITY.md"

echo 'current documentation contract: PASS'
