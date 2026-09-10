#!/usr/bin/env bash
set -euo pipefail

repo=$(cd "$(dirname "$0")/.." && pwd)
box="$repo/boxes/idrac9/zbmc.box"
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT

grep -Fq 'warm restore is unsupported: usb-net returns network-dead' "$box"
grep -Fxq 'ZBMC_REQUIRED_SERVICES="ssh ipmi webui"' "$box"
grep -Fxq 'ZBMC_NETWORK_MODE=tap' "$box"
grep -Fxq 'ZBMC_TAP=ztap-idrac9' "$box"
grep -Fxq 'ZBMC_MAC=52:54:00:fa:00:30' "$box"
grep -Fq 'tap,id=n1,ifname=$ZBMC_TAP,script=no,downscript=no' "$box"
! grep -q 'hostfwd=' "$box"
! grep -q '_zbmc_lo_alias' "$box"
grep -Fq 'CVIP="${CVIP:-10.250.0.30}"' "$repo/boxes/idrac9/build-p4.sh"
grep -Fq 'CVIP="$CVIP" CVMASK="$CVMASK" CVGW="$CVGW"' "$repo/boxes/idrac9/build-p4.sh"
grep -Fq 'os.environ.get("CVIP", "10.0.2.15")' "$repo/boxes/idrac9/scripts/build-cfgdb-defaults.py"
grep -Fq 'CVIP="$ZBMC_IP" CVMASK=255.0.0.0 CVGW=10.0.0.1' "$box"
grep -Fq 'ZBMC_AUTO_WEB=1 zbmc_web' "$repo/tools/zbmc"
! grep -q '\$HOME/phd' "$box"
! grep -q '^zbmc_\(snapshot\|restore\)()' "$box"

cat >"$fixture/start-web.sh" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*"
EOF
chmod +x "$fixture/start-web.sh"
auto=$(bash -c '_zbmc_resolve_ip(){ echo 127.0.0.1; }; . "$1"; PROJ_DIR="$2"; ZBMC_AUTO_WEB=1 zbmc_web' bash "$box" "$fixture")
explicit=$(bash -c '_zbmc_resolve_ip(){ echo 127.0.0.1; }; . "$1"; PROJ_DIR="$2"; zbmc_web --ui-only' bash "$box" "$fixture")
[ "$auto" = --ui-only ] && [ "$explicit" = --ui-only ]

sqlite3 "$fixture/meta.db" <<'SQL'
CREATE TABLE GroupMetaTable (FQDD TEXT, GroupName TEXT, NoOfGroupInstances INT);
CREATE TABLE AttributeMetaTable (FQDD TEXT, GroupName TEXT, AttributeName TEXT, DefaultValue TEXT, MaxLength INT, IsSuppressed INT);
INSERT INTO GroupMetaTable VALUES ('iDRAC.Embedded.1','CurrentIPv4',1);
INSERT INTO AttributeMetaTable VALUES
  ('iDRAC.Embedded.1','CurrentIPv4','Address','0.0.0.0',15,0),
  ('iDRAC.Embedded.1','CurrentIPv4','Netmask','0.0.0.0',15,0),
  ('iDRAC.Embedded.1','CurrentIPv4','Gateway','0.0.0.0',15,0);
SQL
CVIP=10.250.0.30 CVMASK=255.0.0.0 CVGW=10.0.0.1 \
  python3 "$repo/boxes/idrac9/scripts/build-cfgdb-defaults.py" \
  "$fixture/meta.db" "$fixture/defaults.db" evb CurrentIPv4 >/dev/null
[ "$(sqlite3 "$fixture/defaults.db" "SELECT group_concat(AttributeValue, ',') FROM (SELECT AttributeValue FROM CfgValueTable ORDER BY AttributeName)")" = \
  '10.250.0.30,10.0.0.1,255.0.0.0' ]

echo "idrac9 cold-boot contract: PASS"
