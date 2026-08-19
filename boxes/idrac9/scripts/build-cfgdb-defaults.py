#!/usr/bin/env python3
# build-cfgdb-defaults.py — synthesize a populated CfgCurrentValues.db from the iDRAC9
# CfgAttributeMetadata.db default values, so the virtual iDRAC9's cfgdb has real values
# (the factory values normally live in SPI/eMMC flash we don't have; cfgdbinit makes an
# empty store). Unblocks racadm attribute VALUES + fullfw network/IPMI config + RAKP.
#
# PERSISTENT store schema (captured from the box's /var/lib/cfgdb/EMMC/CfgCurrentValues.db):
#   CfgValueTable(FQDD, GroupName, GroupIndex, AttributeName, AttributeValue, AttributeMemSize,
#                 PRIMARY KEY(FQDD,GroupName,GroupIndex,AttributeName))
#   VersionTable(SchemaMajorVersion, SchemaMinorVersion)  -- the box has (1,1)
# cfgmgr loads CfgValueTable from the persistent stores at startup and builds the runtime
# CfgValueTableTmpfs + the datacache_Config_* shm caches that racadm/fullfw read. So we
# populate the PERSISTENT store; cfgmgr does the rest.
#
# Usage: build-cfgdb-defaults.py <CfgAttributeMetadata.db> <out CfgCurrentValues.db> [platform]
import sqlite3, sys, os

meta_path = sys.argv[1]
out_path  = sys.argv[2]
platform  = sys.argv[3] if len(sys.argv) > 3 else "evb"
# optional 4th arg: comma-separated GroupName whitelist (curated subset). Empty/"all" = everything.
# The full 10638-attr load destabilizes cfgmgr; a subset of the groups fullfw/RMCP + basic IPMI
# need keeps cfgmgr stable while still unblocking udp/623.
_g = (sys.argv[4] if len(sys.argv) > 4 else "").strip()
GROUP_WL = set(g for g in _g.split(",") if g) if _g and _g != "all" else None

meta = sqlite3.connect(meta_path)
# group instance counts: how many indexed instances each group has (Users.1..N, etc.)
groups = {}
for fqdd, grp, n in meta.execute("SELECT FQDD,GroupName,NoOfGroupInstances FROM GroupMetaTable"):
    groups[(fqdd, grp)] = n or 1

# per-platform overrides (DefaultValue / IsSuppressed) if the platform table exists
plat_override = {}
try:
    for fqdd, grp, attr, dflt, supp in meta.execute(
            f"SELECT FQDD,GroupName,AttributeName,DefaultValue,IsSuppressed FROM '{platform}'"):
        plat_override[(fqdd, grp, attr)] = (dflt, supp)
except sqlite3.OperationalError:
    pass  # no platform table → base defaults only

# network/IPMI overrides so fullfw's RMCP listener gets a real IP + IPMI-over-LAN enabled
_IP, _MASK, _GW = "10.0.2.15", "255.255.255.0", "10.0.2.2"
NET_OVERRIDE = {}
# fullfw/libtcpi reads CurrentIPv4 (read-only, derived). osinterface derives it from the STATIC
# IPv4/IPv4Static config at startup -> set the static groups so the derivation yields our IP.
for grp in ("CurrentIPv4", "IPv4", "IPv4Static", "NICStatic"):
    NET_OVERRIDE[("iDRAC.Embedded.1", grp, "Address")] = _IP
    NET_OVERRIDE[("iDRAC.Embedded.1", grp, "Netmask")] = _MASK
    NET_OVERRIDE[("iDRAC.Embedded.1", grp, "Gateway")] = _GW
for grp in ("CurrentIPv4", "IPv4"):
    NET_OVERRIDE[("iDRAC.Embedded.1", grp, "Enable")] = "1"
    NET_OVERRIDE[("iDRAC.Embedded.1", grp, "DHCPEnable")] = "0"

if os.path.exists(out_path):
    os.remove(out_path)
out = sqlite3.connect(out_path)
out.execute("""CREATE TABLE CfgValueTable ( FQDD TEXT NOT NULL, GroupName TEXT NOT NULL,
  GroupIndex INT NOT NULL, AttributeName TEXT NOT NULL, AttributeValue TEXT, AttributeMemSize INT,
  PRIMARY KEY (FQDD,GroupName,GroupIndex,AttributeName))""")
out.execute("""CREATE TABLE VersionTable ( SchemaMajorVersion INT NOT NULL,
  SchemaMinorVersion INT NOT NULL, PRIMARY KEY (SchemaMajorVersion,SchemaMinorVersion))""")
out.execute("INSERT INTO VersionTable VALUES (1,1)")

rows, skipped = [], 0
for fqdd, grp, attr, dflt, maxlen, supp in meta.execute(
        "SELECT FQDD,GroupName,AttributeName,DefaultValue,MaxLength,IsSuppressed FROM AttributeMetaTable"):
    o = plat_override.get((fqdd, grp, attr))
    if o is not None:
        if o[0] is not None:
            dflt = o[0]
        if o[1]:
            supp = o[1]
    if supp:                      # suppressed = not applicable to this platform
        skipped += 1
        continue
    if GROUP_WL is not None and grp not in GROUP_WL:
        continue
    no = NET_OVERRIDE.get((fqdd, grp, attr))
    if no is not None:
        dflt = no
    n = groups.get((fqdd, grp), 1) or 1
    for idx in range(1, n + 1):
        rows.append((fqdd, grp, idx, attr, "" if dflt is None else dflt, maxlen or 0))

out.executemany("INSERT OR IGNORE INTO CfgValueTable VALUES (?,?,?,?,?,?)", rows)
out.commit()
print(f"platform={platform}  attrs->{len(rows)} rows  ({skipped} suppressed)")
for f, g, i, a, v in out.execute("SELECT FQDD,GroupName,GroupIndex,AttributeName,AttributeValue "
        "FROM CfgValueTable WHERE GroupName IN ('CurrentIPv4','IPMILANConfig','NICStatic') LIMIT 14"):
    print(f"    {f}#{g}.{i}#{a} = {v!r}")
