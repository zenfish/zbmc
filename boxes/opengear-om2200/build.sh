#!/usr/bin/env bash
# zbmc-lab:turnkey   <- firmware fetched by firmware/download-fw.sh; builds the boot image.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
. "$HERE/zbmc.box"
zbmc_build "$@"
