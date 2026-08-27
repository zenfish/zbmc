#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
tool="$repo/tools/build-qemu"
expected=$'qemu-11-arm\nqemu-11-idrac10\nqemu-11-x10'
[ "$($tool --list)" = "$expected" ]

for recipe in qemu-11-arm qemu-11-idrac10 qemu-11-x10; do
  plan="$($tool --plan "$recipe")"
  grep -Fq '98b060da3a4f92b2a994ead5b16a87e783baf77c (v11.0.0)' <<<"$plan"
  grep -Fq 'Build host  : x86_64-linux' <<<"$plan"
  grep -Fq 'Linkage     : dynamic' <<<"$plan"
  grep -Fq '/home/zen/src/vendor/zbmc-qemu-builds/' <<<"$plan"
  grep -Fq '/home/zen/opt/zbmc-qemu/' <<<"$plan"
done

idrac_plan="$($tool --plan qemu-11-idrac10)"
grep -Fq "$repo/boxes/idrac10/qemu-usb-net-high-speed.patch" <<<"$idrac_plan"
grep -Fq 'Machines    : npcm845-evb' <<<"$idrac_plan"

x10_plan="$($tool --plan qemu-11-x10)"
grep -Fq "$repo/boxes/supermicro-x10/qemu-ftgmac-rx-descriptor.patch" <<<"$x10_plan"
grep -Fq 'Machines    : supermicrox11-bmc' <<<"$x10_plan"

python3 - "$repo/qemu/packages/debian-13-qemu-10.0.11.json" <<'PY'
import json
import sys

data = json.load(open(sys.argv[1]))
assert data["package_version"] == "1:10.0.11+ds-0+deb13u1"
assert data["binary_sha256"] == "584e8a49021e62dabb14ada6407230c8f632cfcade42ef049d19c346ab1314b2"
assert data["boxes"] == ["advantech-asmb787"]
PY

echo 'QEMU build recipes and provenance plans: PASS'
