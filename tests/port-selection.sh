#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

cat >"$fixture/ss" <<'EOF'
#!/usr/bin/env bash
cat <<'OUT'
LISTEN 0 128 0.0.0.0:22 0.0.0.0:*
LISTEN 0 4096 *:443 *:*
LISTEN 0 1024 [::]:8443 [::]:*
OUT
EOF
chmod +x "$fixture/ss"

PATH="$fixture:$PATH"
export PATH
# shellcheck disable=SC1091
ZBMC_SOURCE_ONLY=1 source "$repo/tools/zbmc"
[ "$(_zbmc_pick_port 22 2222 10022)" = 2222 ]
[ "$(_zbmc_pick_port 443 8443 6443 10443)" = 6443 ]
if _zbmc_pick_port 22 443 8443 >/dev/null 2>&1; then
  echo "port picker accepted an occupied candidate" >&2
  exit 1
fi

echo "TCP port selection: PASS"
