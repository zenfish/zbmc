#!/usr/bin/env bash
# zbmc-lab:turnkey   <- Supermicro ATEN firmware fetched by firmware/download-fw.sh; builds the boot image.
#
# build.sh — carve + patch the ATEN AST2600 boot artifacts (kernel.bin / fdt-patched.dtb,
# plus a blank GPT eMMC for the eMMC-root builds) into the box's work dir. The actual work
# is done by the box's zbmc.box zbmc_build (which knows the per-generation FIT offset, rofs
# offset, and eMMC layout); this wrapper just invokes it so the top-level build.sh can find
# and drive the box.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1090
. "$HERE/zbmc.box"
zbmc_build "$@"
