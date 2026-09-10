#!/usr/bin/env bash
# build-p4.sh — repack the Phase-4 initramfs (boot/initramfs.p4.xz) from init.p4.custom.
# Phase 4 = minimal-systemd mesh bring-up (mini.target, DefaultDependencies=no) used to tear
# down the dbus-broker -131 blocker. Reuses the patched kernel + p4.dtb already in boot/.
# Substitutes the VM pubkey (img/vmkey.pub) into the __PUBKEY__ placeholder.
# RUN: ./build-p4.sh   then   ./run-p4.sh
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ART="${WD:-$(cd "$HERE/../.." && pwd)/work/idrac9}"
BOOT="$ART/boot"; IMG="$ART/img"
[ -s "$BOOT/initramfs.p4.xz" ] || { echo "FATAL: missing $BOOT/initramfs.p4.xz — run build.sh first"; exit 1; }
[ -s "$IMG/vmkey" ] || { echo "FATAL: missing $IMG/vmkey — run build.sh first"; exit 1; }
STAGE=$(mktemp -d "$ART/repack.XXXXXXXX")
ROOT="$STAGE/root"; mkdir "$ROOT"
(cd "$ROOT" && xz -dc "$BOOT/initramfs.p4.xz" | cpio -idmu --quiet)
PUB="$(ssh-keygen -y -f "$IMG/vmkey")"
CVIP="${CVIP:-10.250.0.30}"; CVPREFIX="${CVPREFIX:-8}"
CVMASK="${CVMASK:-255.0.0.0}"; CVGW="${CVGW:-10.0.0.1}"
sed -e "s|__PUBKEY__|$PUB|" -e "s|10\.0\.2\.15/24|$CVIP/$CVPREFIX|g" \
    -e "s|10\.0\.2\.15|$CVIP|g" \
    -e "s|255\.255\.255\.0|$CVMASK|g" -e "s|10\.0\.2\.2|$CVGW|g" \
    "$HERE/init.p4.custom" > "$ROOT/init"
chmod +x "$ROOT/init"
# ship synthesized cfgdb factory-default values into the initramfs (prep injects them); build
# them if missing. The real factory values live in flash we don't have — these come from the
# CfgAttributeMetadata defaults (scripts/build-cfgdb-defaults.py).
CVDB="$ROOT/cfgdb-defaults.db"
META="${META:-$ROOT/cfgmeta.db}"
[ -f "$META" ] || { echo "FATAL: installed initramfs has no cfgmeta.db" >&2; exit 1; }
# curated subset (network/IPMI/Users/Info groups) — full 10638-attr load stalls cfgmgr
CVGROUPS="CurrentIPv4,CurrentIPv6,IPv4,IPv4Static,IPv6,IPv6Static,NIC,NICStatic,CurrentNIC,NICVLAN,IPMILANConfig,IPMILan,IPMIIPConfig,IPMISOL,IPMISerial,SNMPTrapIPv4,Users,Info,IPBlocking,SecureDefaultPassword,IPMIUserInfo"
IPMIKEY="${IPMIKEY:-915F32F49A97456D0D6D66EEE5ED84C894B414AFEB69DADFF891AF14F4B98964}"
CVIP="$CVIP" CVMASK="$CVMASK" CVGW="$CVGW" IPMIKEY="$IPMIKEY" \
  python3 "$HERE/scripts/build-cfgdb-defaults.py" "$META" "$CVDB" evb "$CVGROUPS" >/dev/null
# patched metadata: CurrentIPv4 made writable + default = our IP (read-only is why the injected
# CurrentIPv4 value got reset to 0.0.0.0). Regenerated here so the IP is one knob (CVIP). init
# bind-mounts it over the squashfs original so cfgmgr loads CurrentIPv4 writable=CVIP.
[ "$META" = "$ROOT/cfgmeta.db" ] || cp -f "$META" "$ROOT/cfgmeta.db"
python3 - "$ROOT/cfgmeta.db" "$CVIP" "$CVMASK" "$CVGW" <<'PY'
import sqlite3, sys
db, ip, mask, gateway = sys.argv[1:]
con = sqlite3.connect(db)
con.execute("UPDATE AttributeMetaTable SET IsReadonly=0 WHERE GroupName IN ('CurrentIPv4','Users')")
con.execute("UPDATE AttributeMetaTable SET DBLocation=2 WHERE GroupName='Users' AND AttributeName='UserName'")
con.execute("UPDATE AttributeMetaTable SET DBLocation=2, DefaultValue='1' WHERE GroupName='SecureDefaultPassword' AND AttributeName='DefaultUserCreated'")
for attribute, value in (("Address", ip), ("Netmask", mask), ("Gateway", gateway), ("Enable", "1")):
    con.execute("UPDATE AttributeMetaTable SET DefaultValue=? WHERE GroupName='CurrentIPv4' AND AttributeName=?", (value, attribute))
con.commit()
PY
# (No libtcpi patch: the UDPCreateInstance "NIC bail" at 0x376c is a RED HERRING — the NIC index is
# provably 0 (LANChannelInit passes 0), so cmp 1,0; bls never fires. The actual cause of fullfw
# not servicing udp/623 was the SOCKET FAMILY: UDPCreateInstance does an unconditional
# setsockopt(IPV6_RECVPKTINFO) that returns -1 on an AF_INET socket -> RMCPCreateSocketInstance
# fail -> fullfw exits. Fix is in init.p4: socket-activate fullfw on [::]:623 (IPv6 dual-stack),
# matching stock fullfw.socket's BindIPv6Only=both. bindv6only=0 still catches the v4 hostfwd.)
(cd "$ROOT" && find . | cpio -o -H newc 2>/dev/null | xz --check=crc32 -c) > "$BOOT/initramfs.p4.xz.part"
mv "$BOOT/initramfs.p4.xz.part" "$BOOT/initramfs.p4.xz"
echo "built $BOOT/initramfs.p4.xz ($(wc -c < "$BOOT/initramfs.p4.xz") bytes); staging preserved at $STAGE"
