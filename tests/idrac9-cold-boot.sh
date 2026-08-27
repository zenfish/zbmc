#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
box="$repo/boxes/idrac9/zbmc.box"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

grep -Fq 'warm restore is unsupported: usb-net returns network-dead' "$box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES="ssh ipmi webui"' "$box"
grep -Fq 'ZBMC_AUTO_WEB=1 zbmc_web' "$repo/tools/zbmc"
! grep -q '\$HOME/phd' "$box"
! grep -q '^zbmc_\(snapshot\|restore\)()' "$box"

cat >"$fixture/start-web.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*"
EOF
chmod +x "$fixture/start-web.sh"
auto=$(bash -c '_zbmc_resolve_ip(){ echo 127.0.0.1; }; . "$1"; PROJ_DIR="$2"; ZBMC_AUTO_WEB=1 zbmc_web' bash "$box" "$fixture")
explicit=$(bash -c '_zbmc_resolve_ip(){ echo 127.0.0.1; }; . "$1"; PROJ_DIR="$2"; zbmc_web --ui-only' bash "$box" "$fixture")
[ "$auto" = --ui-only ] && [ "$explicit" = --ui-only ]

echo "idrac9 cold-boot contract: PASS"
