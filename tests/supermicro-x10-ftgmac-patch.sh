#!/usr/bin/env bash
set -euo pipefail

patch="$(dirname "$0")/../qemu/patches/ftgmac100-rx-descriptor-reuse.patch"
box="$(dirname "$0")/../boxes/supermicro-x10/zbmc.box"
driver="$(dirname "$0")/../boxes/supermicro-x10/start-x10.py"

test -f "$patch"
grep -q 'ZBMC_QEMU=/home/zen/opt/qemu-11/bin/qemu-system-arm' "$box"
grep -q 'ZBMC_QEMU_SHA256=d70c04a3dfe5515ab0979247dc1d6f76cb2c809b4f9d6370397be9f7a0d118cc' "$box"
addressing=$(bash -c '
  _zbmc_resolve_ip(){ echo 10.0.8.10; }
  . "$1"
  printf "%s|%s|%s|%s|%s" "$SSH_PORT" "$WEB_PORT" "$ZBMC_NETWORK_MODE" "$ZBMC_TAPS" "$ZBMC_MAC"
' bash "$box")
[ "$addressing" = '22|443|tap|ztap-x10 ztap-x10-aux|4a:0a:ab:7c:96:2f' ]
grep -Fq 'GUEST_IP = os.environ.get("X10_GUEST_IP", HOSTIP)' "$driver"
grep -Fq 'IFACE = os.environ.get("X10_IFACE", "eth1")' "$driver"
grep -Fq 'tap,id=bmcnet,ifname={TAP},script=no,downscript=no' "$driver"
grep -Fq 'os.environ.get("ZBMC_X10_GDB") == "1"' "$driver"
grep -Fq '"chmod", "660"' "$driver"
! grep -Fq '"chmod", "777"' "$driver"
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
