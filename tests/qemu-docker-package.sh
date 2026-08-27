#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
tool="$repo/tools/package-qemu-docker"
fixture="$(mktemp -d)"
trap 'rm -rf "$fixture"' EXIT
mkdir -p "$fixture/bin" "$fixture/inputs"

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else shasum -a 256 "$1" | awk '{print $1}'; fi
}

dist_binary="$fixture/inputs/qemu-system-arm"
source_binary="$fixture/inputs/qemu-system-aarch64"
source_data="$fixture/inputs/npcm8xx_bootrom.bin"
printf '#!/usr/bin/env bash\nexit 0\n' >"$dist_binary"
printf '#!/usr/bin/env bash\nexit 0\n' >"$source_binary"
printf 'source firmware data\n' >"$source_data"
chmod +x "$dist_binary" "$source_binary"
dist_sha="$(sha256 "$dist_binary")"
source_sha="$(sha256 "$source_binary")"
source_data_sha="$(sha256 "$source_data")"
dist_data_sha="$(printf 'distribution firmware data\n' | { if command -v sha256sum >/dev/null 2>&1; then sha256sum; else shasum -a 256; fi; } | awk '{print $1}')"

dist_manifest="$fixture/inputs/dist.json"
source_manifest="$fixture/inputs/source.json"
python3 - "$dist_manifest" "$source_manifest" "$dist_binary" "$dist_sha" \
  "$source_binary" "$source_sha" "$source_data" "$source_data_sha" "$dist_data_sha" <<'PY'
import json
import sys

(dist_manifest, source_manifest, dist_binary, dist_sha, source_binary,
 source_sha, source_data, source_data_sha, dist_data_sha) = sys.argv[1:]
with open(dist_manifest, "w", encoding="utf-8") as stream:
    json.dump({
        "schema": 1,
        "kind": "distribution-package",
        "build_id": "fixture-dist",
        "binary": dist_binary,
        "binary_sha256": dist_sha,
        "package_version": "1:10.0.11-fixture",
        "machines": ["ast2600-evb"],
        "data_files": [{
            "installed": "/usr/share/qemu/dist.bin",
            "sha256": dist_data_sha,
        }],
    }, stream)
with open(source_manifest, "w", encoding="utf-8") as stream:
    json.dump({
        "schema": 2,
        "build_id": "fixture-source",
        "binary": source_binary,
        "binary_sha256": source_sha,
        "machines": ["npcm845-evb"],
        "data_files": [{
            "installed": source_data,
            "sha256": source_data_sha,
        }],
    }, stream)
PY

cat >"$fixture/bin/uname" <<'EOF'
#!/usr/bin/env bash
case "$1" in
  -s) echo Linux ;;
  -m) echo x86_64 ;;
  *) exit 2 ;;
esac
EOF

cat >"$fixture/bin/timeout" <<'EOF'
#!/usr/bin/env bash
[ "$1" = --foreground ]; shift
[ "$1" = -s ] && [ "$2" = TERM ]; shift 2
[ "$1" = -k ] && [ "$2" = 5 ]; shift 2
duration="$1"; shift
printf 'timeout %s %s\n' "$duration" "$*" >>"$TIMEOUT_LOG"
exec "$@"
EOF

cat >"$fixture/bin/install" <<'EOF'
#!/usr/bin/env bash
mode=
while [ $# -gt 0 ]; do
  case "$1" in
    -D) shift ;;
    -m) mode="$2"; shift 2 ;;
    -Dm*) mode="${1#-Dm}"; shift ;;
    *) break ;;
  esac
done
[ $# -eq 2 ]
mkdir -p "$(dirname "$2")"
cp "$1" "$2"
[ -z "$mode" ] || chmod "$mode" "$2"
EOF

cat >"$fixture/bin/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$DOCKER_LOG"
action="$1"; shift
case "$action" in
  build)
    exit 0
    ;;
  run)
    [ "$1" = --rm ]; shift
    if [ "${1:-}" = -i ]; then shift; fi
    tag="$1"; command="$2"; shift 2
    if [ "$command" = sha256sum ]; then
      path="$1"
      if [ "${FAIL_IMAGE_DATA_PATH:-}" = "$path" ]; then
        printf '%064d  %s\n' 0 "$path"
        exit 0
      fi
      case "$path" in
        /usr/bin/qemu-system-arm) sha="$DIST_SHA" ;;
        /usr/share/qemu/dist.bin) sha="$DIST_DATA_SHA" ;;
        "$SOURCE_BINARY") sha="$SOURCE_SHA" ;;
        "$SOURCE_DATA") sha="$SOURCE_DATA_SHA" ;;
        *) echo "unexpected image hash path: $path" >&2; exit 1 ;;
      esac
      printf '%s  %s\n' "$sha" "$path"
    elif [ "${1:-}" = -machine ] && [ "${2:-}" = help ]; then
      printf 'ast2600-evb fixture\nnpcm845-evb fixture\n'
    elif [ "${1:-}" = -M ]; then
      cat >/dev/null
      printf '%s\n' '{"QMP":{"version":{},"capabilities":[]}}' '{"return":{}}'
    else
      echo "unexpected docker run: $tag $command $*" >&2
      exit 1
    fi
    ;;
  save)
    [ "$1" = -o ]
    printf 'fake docker archive\n' >"$2"
    ;;
  *)
    echo "unexpected docker action: $action" >&2
    exit 1
    ;;
esac
EOF
chmod +x "$fixture/bin/uname" "$fixture/bin/timeout" "$fixture/bin/install" "$fixture/bin/docker"

manifest_tag() {
  python3 - "$repo/qemu/Dockerfile" "$@" <<'PY'
import hashlib
import pathlib
import sys

digest = hashlib.sha256()
for manifest in sys.argv[1:]:
    contents = pathlib.Path(manifest).read_bytes()
    digest.update(len(contents).to_bytes(8, "big"))
    digest.update(contents)
print(f"zbmc-qemu:{digest.hexdigest()}")
PY
}

grep -Fq 'FROM debian:13-slim@sha256:' "$repo/qemu/Dockerfile"

export DOCKER_LOG="$fixture/docker.log" TIMEOUT_LOG="$fixture/timeout.log"
export DIST_SHA="$dist_sha" DIST_DATA_SHA="$dist_data_sha"
export SOURCE_BINARY="$source_binary" SOURCE_SHA="$source_sha"
export SOURCE_DATA="$source_data" SOURCE_DATA_SHA="$source_data_sha"
export PATH="$fixture/bin:$PATH"

tag_one="$(manifest_tag "$dist_manifest" "$source_manifest")"
output_one="$fixture/one.tar"
output_two="$fixture/two.tar"
QEMU_DOCKER_RUN_TIMEOUT_SECONDS=7 "$tool" "$output_one" "$dist_manifest" "$source_manifest" >/dev/null
QEMU_DOCKER_RUN_TIMEOUT_SECONDS=7 "$tool" "$output_two" "$dist_manifest" "$source_manifest" >/dev/null
[ "$(grep -Fc -- "-t $tag_one " "$DOCKER_LOG")" -eq 2 ]
grep -Fx "save -o $output_one $tag_one" "$DOCKER_LOG"
grep -Fx "save -o $output_two $tag_one" "$DOCKER_LOG"
[ -f "$output_one" ] && [ -f "$output_two" ]

printf '\n' >>"$source_manifest"
tag_two="$(manifest_tag "$dist_manifest" "$source_manifest")"
[ "$tag_one" != "$tag_two" ]
output_three="$fixture/three.tar"
QEMU_DOCKER_RUN_TIMEOUT_SECONDS=7 "$tool" "$output_three" "$dist_manifest" "$source_manifest" >/dev/null
grep -Fq -- "-t $tag_two " "$DOCKER_LOG"
grep -Fq "run --rm $tag_two sha256sum /usr/share/qemu/dist.bin" "$DOCKER_LOG"
grep -Fq "run --rm $tag_two sha256sum $source_data" "$DOCKER_LOG"

docker_runs="$(grep -c '^run ' "$DOCKER_LOG")"
timeout_runs="$(grep -c '^timeout 7 docker run ' "$TIMEOUT_LOG")"
[ "$docker_runs" -eq "$timeout_runs" ]

output_bad="$fixture/bad.tar"
if FAIL_IMAGE_DATA_PATH="$source_data" QEMU_DOCKER_RUN_TIMEOUT_SECONDS=7 \
  "$tool" "$output_bad" "$dist_manifest" "$source_manifest" >"$fixture/bad.out" 2>&1; then
  echo "packager accepted an in-image data hash mismatch" >&2
  exit 1
fi
grep -Fq "Docker data hash mismatch: $source_data" "$fixture/bad.out"
[ ! -e "$output_bad" ]

echo 'QEMU Docker package contract: PASS'
