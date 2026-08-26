#!/usr/bin/env bash
set -euo pipefail

patch="$(dirname "$0")/../boxes/supermicro-x10/qemu-ftgmac-rx-descriptor.patch"

test -f "$patch"
test "$(grep -c '^diff --git ' "$patch")" -eq 1
test "$(grep -c '^@@ ' "$patch")" -eq 1
test "$(grep -Ec '^[+-][^+-]' "$patch")" -eq 3
grep -q '^diff --git a/hw/net/ftgmac100.c b/hw/net/ftgmac100.c$' "$patch"
grep -q '^+        bd.des0 &= s->rxdes0_edorr;$' "$patch"
grep -q '^-        bd.des0 |= buf_len & 0x3fff;$' "$patch"
grep -q '^+        bd.des0 |= buf_len & FTGMAC100_RXDES0_VDBC;$' "$patch"

python3 - <<'PY'
stale_vdbc = 0x5ff
received_with_fcs = 544 + 4
mask = 0x3fff

assert (stale_vdbc | received_with_fcs) & mask == 0x7ff
assert received_with_fcs & mask == 548
assert 0x7ff - 4 == 2043
PY

echo "supermicro-x10 FTGMAC recycled RX descriptor patch: PASS"
