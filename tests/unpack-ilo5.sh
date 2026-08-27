#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

touch "$tmp/ilo5_241.bin"
output=$("$repo/tools/unpack-ilo5" "$tmp/ilo5_241.bin")
grep -Fq 'format:  bin' <<<"$output"
grep -Fq 'check: ready; use --write to unpack' <<<"$output"
[ ! -e "$tmp/ilo5_241.unpacked" ]

echo "PASS: unpack-ilo5 defaults to a read-only dependency and input check"

mkdir "$tmp/bin"
real_python=$(command -v python3)
cat > "$tmp/bin/python3" <<EOF
#!/usr/bin/env bash
if [[ "\$*" == *'from Crypto.Cipher import AES'* ]]; then exit 1; fi
if [[ "\$*" == *'from Cryptodome.Cipher import AES'* ]]; then exit 0; fi
exec "$real_python" "\$@"
EOF
chmod +x "$tmp/bin/python3"
output=$(PATH="$tmp/bin:$PATH" "$repo/tools/unpack-ilo5" "$tmp/ilo5_241.bin")
grep -Fq 'check: ready; use --write to unpack' <<<"$output"

echo "PASS: unpack-ilo5 accepts Debian's Cryptodome namespace"
