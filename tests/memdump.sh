#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
helper="$repo/tools/zbmc-memdump"

python3 -m py_compile "$helper"
grep -Fq 'memdump [DIR]' "$repo/tools/zbmc"
grep -Fq 'memdump one box at a time' "$repo/tools/zbmc"
grep -Fq 'dump-guest-memory' "$helper"
grep -Fq 'info mtree -f' "$helper"
grep -Fq 'ZBMC_MEMDUMP_REGIONS' "$helper"
grep -Fq 'ZBMC_MEMDUMP_GDB_SCRIPT' "$helper"
grep -Fq 'ZBMC_MEMDUMP_REGIONS="sram:0x10000000:0x16400"' "$repo/boxes/lenovo-xcc/zbmc.box"
grep -Fq 'lenovo-fpga-command.bin' "$repo/boxes/lenovo-xcc/memdump.gdb"
grep -Fq -- '-qmp "unix:$QMP_SOCK,server=on,wait=off"' "$repo/boxes/idrac9/zbmc.box"
grep -Fq -- '-qmp "unix:$QMP_SOCK,server=on,wait=off"' "$repo/boxes/nvidia-obmc/zbmc.box"
grep -Fq 'gcore", "-a"' "$helper"
grep -Fq 'qmp.command("cont")' "$helper"
grep -Fq 'SUDO_UID' "$helper"
grep -Fq 'os.chmod(path, 0o600)' "$helper"
grep -Fq 'sudo ./tools/zbmc openbmc memdump' "$repo/GETTING-STARTED.md"

echo 'memdump command contract: PASS'
