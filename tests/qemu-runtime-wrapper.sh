#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

cat >"$fixture/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$DOCKER_LOG"
case "$1" in
  info) exit 0 ;;
  run) [[ " $* " == *' --detach '* ]] && echo fixture-container; exit 0 ;;
  wait) echo 0 ;;
  stop) exit 0 ;;
esac
EOF
chmod +x "$fixture/docker"
export DOCKER_LOG="$fixture/docker.log" PATH="$fixture:$PATH"

ZBMC_QEMU_DOCKER_DETACH=1 "$repo/tools/zbmc-qemu-docker" /qemu -M fixture
grep -Fq 'run --rm --network host --pid host --privileged' "$DOCKER_LOG"
grep -Fq -- '--detach sha256:0e03b041c9014a8be084d4fa72413c8db6a9897bdabab9804a9f302dc461fa3f /qemu -M fixture' "$DOCKER_LOG"
grep -Fxq 'wait fixture-container' "$DOCKER_LOG"

: >"$DOCKER_LOG"
"$repo/tools/zbmc-qemu-docker" /qemu --version
grep -Fq -- '-i sha256:0e03b041c9014a8be084d4fa72413c8db6a9897bdabab9804a9f302dc461fa3f /qemu --version' "$DOCKER_LOG"

echo 'QEMU runtime wrapper lifecycle: PASS'
