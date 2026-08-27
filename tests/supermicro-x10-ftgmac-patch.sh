#!/usr/bin/env bash
set -euo pipefail

patch="$(dirname "$0")/../qemu/patches/ftgmac100-rx-descriptor-reuse.patch"
box="$(dirname "$0")/../boxes/supermicro-x10/zbmc.box"

test -f "$patch"
grep -q 'qemu/runtime/qemu-system-arm' "$box"
grep -q 'ZBMC_QEMU_SHA256=a066ffd52f50bc4555ea9af003e44e02aec3b3d260a37da8ab0b3d8c596790a6' "$box"
user_mode=$(bash -c '
  _zbmc_resolve_ip(){ echo 10.0.8.10; }
  _zbmc_pick_port(){ echo "$2"; }
  _zbmc_lo_alias(){ :; }
  . "$1"
  printf "%s|%s|%s|%s|%s" "$X10_NET_MODE" "$SSH_PORT" "$WEB_PORT" "$ZBMC_L2_REQUIRED" "$ZBMC_CAPTURE_INTERFACES"
' bash "$box")
[ "$user_mode" = 'user|2222|8443|0|' ]
active_mode=$(bash -c '
  _zbmc_resolve_ip(){ echo 10.0.8.10; }
  _zbmc_pick_port(){ echo "$3"; }
  _zbmc_lo_alias(){ :; }
  pgrep(){ printf "%s\n" "123 /qemu-system-arm -net user,hostfwd=udp:10.0.8.10:623-:623,hostfwd=tcp:10.0.8.10:2222-:22,hostfwd=tcp:10.0.8.10:6443-:443,hostname=qemu"; }
  . "$1"
  printf "%s|%s" "$SSH_PORT" "$WEB_PORT"
' bash "$box")
[ "$active_mode" = '2222|6443' ]
direct_mode=$(X10_NET_MODE=direct bash -c '
  _zbmc_resolve_ip(){ echo 10.0.8.10; }
  _zbmc_pick_port(){ echo "$2"; }
  _zbmc_lo_alias(){ :; }
  . "$1"
  printf "%s|%s|%s|%s|%s" "$X10_NET_MODE" "$SSH_PORT" "$WEB_PORT" "$ZBMC_L2_REQUIRED" "$ZBMC_CAPTURE_INTERFACES"
' bash "$box")
[ "$direct_mode" = 'direct|22|443|1|br-zbmc ztap-x10 ztap-x10-aux' ]
grep -Fq "_zbmc_lo_alias \"\$ZBMC_IP\"" "$box"
grep -Fq "hostfwd=udp:\$ZBMC_IP:\$ZBMC_HOSTPORT-:623" "$box"
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
