#!/usr/bin/env bash
# build.sh — build the QEMU boot artifacts for every box that can be built.
#
# A box is buildable when it has a recipe (boxes/<box>/build.sh) AND its firmware is present
# (the Advantech image ships in this repo; the big Dell/Supermicro images are fetched by
# firmware/download-fw.sh into firmware/<box>/). Each box builds into work/<box>/.
#
# USAGE:  ./build.sh              # build everything that can be built
#         ./build.sh advantech-asmb787   # just one box
#         ./build.sh --list       # show each box's status without building
set -uo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"

want=(); listonly=0
for a in "$@"; do case "$a" in --list|-l) listonly=1;; *) want+=("$a");; esac; done

# stub dispatcher helpers so zbmc.box files can source without error
_zbmc_resolve_ip() { echo "${3:-127.0.0.1}"; }; export -f _zbmc_resolve_ip
_zbmc_lo_alias() { :; }; export -f _zbmc_lo_alias
_zbmc_pick_port() { echo "$1"; }; export -f _zbmc_pick_port

built=(); skipped=(); failed=()
for boxdir in "$HERE"/boxes/*/; do
  box="$(basename "$boxdir")"
  # honour an explicit box list
  if [ "${#want[@]}" -gt 0 ]; then
    printf '%s\n' "${want[@]}" | grep -qx "$box" || continue
  fi
  # a box is turnkey (clone-buildable) only if its build.sh carries the marker; the others
  # carry the author's session build scripts, kept as reference recipes.
  if ! grep -q 'zbmc:turnkey' "$boxdir/build.sh" 2>/dev/null; then
    skipped+=("$box  (reference recipe — supply firmware + adapt boxes/$box/; see docs/zoo-lessons.md)")
    continue
  fi
  if [ "$listonly" = 1 ]; then echo "buildable: $box"; continue; fi
  # skip if already built — source zbmc.box for zbmc_ready()
  if [ -f "$boxdir/zbmc.box" ]; then
    (ZBMC_DIR="$HERE/work/$box"; export ZBMC_DIR; . "$boxdir/zbmc.box"; \
     declare -F zbmc_ready >/dev/null && zbmc_ready >/dev/null 2>&1) && {
      echo "SKIP    ✓ $box  (already built)"
      continue
    }
  fi
  echo "=============================================================="
  echo "  building: $box"
  echo "=============================================================="
  if bash "$boxdir/build.sh"; then built+=("$box"); else failed+=("$box"); fi
  echo
done

echo "=============================================================="
for b in "${built[@]:-}";   do [ -n "$b" ] && echo "BUILT   ✓ $b   -> work/$b/"; done
for b in "${failed[@]:-}";  do [ -n "$b" ] && echo "FAILED  ✗ $b   (firmware missing? run ./firmware/download-fw.sh $b)"; done
for b in "${skipped[@]:-}"; do [ -n "$b" ] && echo "ref     – $b"; done
echo
echo "run a built box:   ./tools/zbmc <box> start   (then: ./tools/zbmc <box> console)"
