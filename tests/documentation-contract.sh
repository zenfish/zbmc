#!/usr/bin/env bash
# z-artifact: b64fbca9-07eb-4bbc-a9ee-761568cb8686
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)

python3 - "$repo" <<'PY'
from html.parser import HTMLParser
import pathlib
import re
import subprocess
import sys

root = pathlib.Path(sys.argv[1]).resolve()
documents = [root / path for path in subprocess.check_output(
    ["git", "ls-files", "--cached", "--others", "--exclude-standard", "--", "*.md", "*.html"],
    cwd=root,
    text=True,
).splitlines()]
missing = []
wrong_format = []

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
            continue
        if path.suffix in (".md", ".html") and path.suffix != document.suffix:
            preferred = path.with_suffix(document.suffix)
            if preferred.exists():
                wrong_format.append(
                    f"{document.relative_to(root)} -> {target}; "
                    f"prefer {preferred.relative_to(root)}"
                )
if missing:
    raise SystemExit("missing documentation links:\n" + "\n".join(missing))
if wrong_format:
    raise SystemExit("cross-format documentation links:\n" + "\n".join(wrong_format))
PY

"$repo/tools/sync-docs"

grep -Fq 'sudo ./tools/zbmc openbmc start' "$repo/README.md"
grep -Fq 'sudo ./tools/zbmc openbmc start' "$repo/GETTING-STARTED.md"
! grep -Eq '(^|`)sudo zbmc openbmc start' "$repo/README.md" "$repo/GETTING-STARTED.md"
grep -Fq 'sudo ./tools/zbmc idrac10 snapshot' "$repo/GETTING-STARTED.md"
grep -Fq 'sudo ./tools/zbmc idrac10 start --warm' "$repo/GETTING-STARTED.md"
grep -Fq 'git.trouble.org' "$repo/GETTING-STARTED.md" "$repo/boxes/idrac10/WARM-START.md"
grep -Fq 'boxes/idrac10/WARM-START.md' "$repo/README.md" "$repo/GETTING-STARTED.md"
grep -Fq 'Docker packages exact QEMU builds' "$repo/SECURITY.md"

# OEM status must distinguish a closed inventory from operation-level completion.
grep -Fq 'Inventory complete' "$repo/docs/oem-ipmi-coverage-audit.md"
grep -Fq 'Registration inventory complete; deep dive open' "$repo/docs/oem-ipmi-coverage-audit.md"
grep -Fq 'Supermicro X11 remains open after its top-level denominator closed' "$repo/docs/oem-ipmi-coverage-audit.md"
grep -Fq 'no global semantic-operation count' "$repo/boxes/megarac-hpe/IPMI.md"
grep -Fq 'OEM deep dive open' "$repo/boxes/idrac9/index.md"
grep -Fq 'OEM deep dive open' "$repo/boxes/idrac6/index.md"
grep -Fq 'The registration inventory is closed; the deep dive remains open.' "$repo/boxes/irmc-fujitsu/index.md"
grep -Fq '123 remain' "$repo/boxes/idrac9/index.md"
grep -Fq '157 effective routes' "$repo/boxes/idrac6/index.md"
grep -Fq '688 exact paths' "$repo/boxes/irmc-fujitsu/index.md"
grep -Fq 'ieit-nf5468m6-command-reference.html' "$repo/boxes/ieit/index.md"
grep -Fq 'nvidia-gb200-command-reference.html' "$repo/boxes/nvidia-obmc/index.md"
grep -Fq 'openbmc-vanilla-command-reference.html' "$repo/boxes/openbmc/index.md"
grep -Fq 'supermicro-x10-command-reference.html' "$repo/boxes/supermicro-x10/README.md"
grep -Fq 'supermicro-x14-command-reference.html' "$repo/boxes/supermicro-x14/index.md"

# Pandoc omits content outside <main>; preserve Lenovo's recovery evidence.
grep -Fxq '## 13 September: native services recovered on TAP' "$repo/boxes/lenovo-xcc/index.md"
grep -Fxq '## 13 September: isolated TAP warm recovery verified' "$repo/boxes/lenovo-xcc/index.md"
grep -Fxq '## 13 September: cold verification failed' "$repo/boxes/lenovo-xcc/index.md"

echo 'current documentation contract: PASS'
