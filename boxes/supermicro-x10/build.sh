#!/usr/bin/env bash
# zbmc-lab:turnkey   <- flat flash boots directly under qemu -M supermicrox11-bmc; no unpacking needed.
#
# build.sh — fetch the X10 firmware and stage it. The pexpect boot driver (start-x10.py) copies
# the master flash to a run image itself, so build just ensures the firmware exists.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
FW="$ROOT/firmware/x10-master.flash"

[ -f "$FW" ] || bash "$ROOT/firmware/download-fw.sh" supermicro-x10
[ -f "$FW" ] || { echo "firmware not found and fetch failed: $FW" >&2; exit 1; }
echo "[*] firmware ready: $FW ($(stat -f '%z' "$FW" 2>/dev/null || stat -c '%s' "$FW") bytes)"
echo
echo "next:  ./tools/zbmc supermicro-x10 start      # cold boot ~60s"
echo "       ./tools/zbmc supermicro-x10 ssh         # root shell (ADMIN:ADMIN)"
echo "       ./tools/zbmc supermicro-x10 ipmi mc info  # RMCP+ cipher 0-14"
