#!/usr/bin/env bash
# Compatibility name retained for older notes. The maintained recipe is build-from-hpm.sh.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
exec bash "$HERE/build-from-hpm.sh"
