#!/usr/bin/env python3
"""Generate cfgdb default INSERTs from the metadata database in the iDRAC rootfs."""

import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path


def quote(value: object) -> str:
    return "'" + str(value or "").replace("'", "''") + "'"


def main() -> int:
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} SD_SQUASHFS OUTPUT_SQL", file=sys.stderr)
        return 2
    image, output = map(Path, sys.argv[1:])
    with tempfile.TemporaryDirectory() as tmp:
        metadata = Path(tmp) / "CfgAttributeMetadata.db"
        with metadata.open("wb") as stream:
            subprocess.run(
                ["unsquashfs", "-cat", str(image), "usr/share/cfgdb/CfgAttributeMetadata.db"],
                stdout=stream,
                check=True,
            )
        db = sqlite3.connect(metadata)
        rows = db.execute(
            """
            SELECT a.FQDD, a.GroupName, a.AttributeName,
                   COALESCE(a.DefaultValue, ''), g.NoOfGroupInstances
              FROM AttributeMetaTable a
              JOIN GroupMetaTable g USING (FQDD, GroupName)
             ORDER BY a.FQDD, a.GroupName, a.AttributeName
            """
        )
        output.parent.mkdir(parents=True, exist_ok=True)
        with output.open("w", encoding="utf-8", newline="\n") as stream:
            stream.write("-- Generated from usr/share/cfgdb/CfgAttributeMetadata.db; do not edit.\nBEGIN;\n")
            for fqdd, group, attribute, default, count in rows:
                for index in range(1, count + 1):
                    key = f"{fqdd}#{group}.{index}#{attribute}"
                    values = ",".join(map(quote, (key, fqdd, group)))
                    values += f",{index},{quote(attribute)},{quote(default)},{len(default.encode())}"
                    stream.write(
                        "INSERT OR IGNORE INTO CfgValueTableTmpfs"
                        "(AttributeKey,FQDD,GroupName,GroupIndex,AttributeName,AttributeValue,AttributeMemSize) "
                        f"VALUES({values});\n"
                    )
            stream.write("COMMIT;\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
