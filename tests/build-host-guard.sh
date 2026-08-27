#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT

cat >"$fixture/uname" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  -s) printf '%s\n' "${FAKE_UNAME_S:?}" ;;
  -m) printf '%s\n' "${FAKE_UNAME_M:?}" ;;
  *) exit 2 ;;
esac
EOF
chmod +x "$fixture/uname"

if output=$(PATH="$fixture:$PATH" FAKE_UNAME_S=Linux FAKE_UNAME_M=aarch64 \
    "$repo/build.sh" --list 2>&1); then
  echo "build.sh accepted an ARM64 host" >&2
  exit 1
fi
grep -Fq 'zbmc v1 supports only x86_64 Linux; detected Linux/aarch64.' <<<"$output"
if grep -q '^buildable:' <<<"$output"; then
  echo "build.sh loaded boxes before rejecting the host" >&2
  exit 1
fi

if output=$(PATH="$fixture:$PATH" FAKE_UNAME_S=Darwin FAKE_UNAME_M=x86_64 \
    "$repo/build.sh" --list 2>&1); then
  echo "build.sh accepted macOS" >&2
  exit 1
fi
grep -Fq 'zbmc v1 supports only x86_64 Linux; detected Darwin/x86_64.' <<<"$output"

output=$(PATH="$fixture:$PATH" FAKE_UNAME_S=Linux FAKE_UNAME_M=x86_64 \
  "$repo/build.sh" --list)
grep -Fxq 'buildable: advantech-asmb787' <<<"$output"

echo 'build host guard: PASS'
