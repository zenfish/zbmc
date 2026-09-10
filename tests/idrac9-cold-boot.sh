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
grep -Fq 'E=/newroot/run/systemd/system.conf.d' "$repo/boxes/idrac9/init.p4.custom"
! grep -q 'E=/newroot/etc/systemd/system.conf.d' "$repo/boxes/idrac9/init.p4.custom"
grep -Fq 'CVIP="${CVIP:-10.250.0.30}"' "$repo/boxes/idrac9/build-p4.sh"
grep -Fq 'CVPREFIX="${CVPREFIX:-8}"' "$repo/boxes/idrac9/build-p4.sh"
grep -Fq 'ART="${WD:-$(cd "$HERE/../.." && pwd)/work/idrac9}"' "$repo/boxes/idrac9/build-p4.sh"
grep -Fq 'xz -dc "$BOOT/initramfs.p4.xz" | cpio -idmu --quiet' "$repo/boxes/idrac9/build-p4.sh"
grep -Fq 'CVIP="$CVIP" CVMASK="$CVMASK" CVGW="$CVGW"' "$repo/boxes/idrac9/build-p4.sh"
grep -Fq 'os.environ.get("CVIP", "10.0.2.15")' "$repo/boxes/idrac9/scripts/build-cfgdb-defaults.py"
grep -Fq 'CVIP="$ZBMC_IP" CVPREFIX=8 CVMASK=255.0.0.0 CVGW=10.0.0.1' "$box"
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

python3 - "$fixture/meta.db" <<'PY'
import sqlite3, sys
con = sqlite3.connect(sys.argv[1])
con.execute("CREATE TABLE GroupMetaTable (FQDD TEXT, GroupName TEXT, NoOfGroupInstances INT)")
con.execute("CREATE TABLE AttributeMetaTable (FQDD TEXT, GroupName TEXT, AttributeName TEXT, DefaultValue TEXT, MaxLength INT, IsSuppressed INT)")
con.execute("INSERT INTO GroupMetaTable VALUES ('iDRAC.Embedded.1','CurrentIPv4',1)")
con.executemany("INSERT INTO AttributeMetaTable VALUES (?,?,?,?,?,0)", [
    ('iDRAC.Embedded.1','CurrentIPv4','Address','0.0.0.0',15),
    ('iDRAC.Embedded.1','CurrentIPv4','Netmask','0.0.0.0',15),
    ('iDRAC.Embedded.1','CurrentIPv4','Gateway','0.0.0.0',15)])
con.commit()
PY
CVIP=10.250.0.30 CVMASK=255.0.0.0 CVGW=10.0.0.1 \
  python3 "$repo/boxes/idrac9/scripts/build-cfgdb-defaults.py" \
  "$fixture/meta.db" "$fixture/defaults.db" evb CurrentIPv4 >/dev/null
python3 - "$fixture/defaults.db" <<'PY'
import sqlite3, sys
values = [row[0] for row in sqlite3.connect(sys.argv[1]).execute(
    "SELECT AttributeValue FROM CfgValueTable ORDER BY AttributeName")]
assert values == ['10.250.0.30', '10.0.0.1', '255.0.0.0'], values
PY

echo "idrac9 cold-boot contract: PASS"
