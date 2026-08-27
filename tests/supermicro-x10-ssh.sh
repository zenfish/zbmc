#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

cat >"$fixture/ssh" <<'EOF'
#!/usr/bin/env bash
[ "${1:-}" = -Q ] && { printf 'ssh-rsa\nssh-dss\n'; exit; }
cat
EOF
cat >"$fixture/sshpass" <<'EOF'
#!/usr/bin/env bash
[ "$1" = -p ] && shift 2
exec "$@"
EOF
chmod +x "$fixture/ssh" "$fixture/sshpass"
PATH="$fixture:$PATH"
_zbmc_resolve_ip(){ echo 127.0.0.1; }
_zbmc_pick_port(){ echo "$1"; }
. "$repo/boxes/supermicro-x10/zbmc.box"

[ "$(zbmc_ssh uname -a)" = $'uname -a\nexit' ]
[ "$(zbmc_ssh echo up)" = up ]

echo 'Supermicro X10 SSH command transport: PASS'
