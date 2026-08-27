#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/repo/tools" "$tmp/repo/renode" "$tmp/pkg/renode_1.16.1-dotnet_portable" "$tmp/bin"
cp "$repo/tools/install-renode-runtime" "$tmp/repo/tools/"

cat > "$tmp/pkg/renode_1.16.1-dotnet_portable/renode" <<'SH'
#!/bin/sh
printf 'Renode v1.16.1.16973\n  build: d66b0c2a-202602160923\n  build type: Release\n'
SH
chmod +x "$tmp/pkg/renode_1.16.1-dotnet_portable/renode"
tar -czf "$tmp/renode.tar.gz" -C "$tmp/pkg" renode_1.16.1-dotnet_portable

cat > "$tmp/bin/uname" <<'SH'
#!/bin/sh
[ "$1" = -s ] && echo Linux || echo x86_64
SH
cat > "$tmp/bin/curl" <<'SH'
#!/bin/sh
while [ "$#" -gt 0 ]; do
  if [ "$1" = -o ]; then cp "$FIXTURE_ARCHIVE" "$2"; exit; fi
  shift
done
exit 1
SH
cat > "$tmp/bin/sha256sum" <<'SH'
#!/bin/sh
cat >/dev/null
SH
chmod +x "$tmp/bin/"*

if PATH="$tmp/bin:$PATH" "$tmp/repo/tools/install-renode-runtime" >/dev/null 2>&1; then
  echo "default check unexpectedly installed Renode" >&2
  exit 1
fi
[ ! -e "$tmp/repo/renode/runtime" ]
FIXTURE_ARCHIVE="$tmp/renode.tar.gz" PATH="$tmp/bin:$PATH" \
  "$tmp/repo/tools/install-renode-runtime" --write >/dev/null
PATH="$tmp/bin:$PATH" "$tmp/repo/tools/install-renode-runtime" --check >/dev/null

echo "PASS: Renode runtime installer is explicit, pinned, and self-checking"
