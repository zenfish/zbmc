#!/usr/bin/env python3
"""Derive the pinned ASMB-787 direct-PHY kernel payload from its zImage."""

import hashlib
import lzma
import pathlib
import sys

SOURCE_SHA256 = "914c2397220eb2661ed32226cec0e2c26d2e2b8cdd60079410fd07a59b4c1811"
RAW_SHA256 = "45cf4079288ef9a3fc0380052aac83df6793807d934db2d3615db962ad3c8a9f"
PATCHED_SHA256 = "1f165f23f67a671362d65275d341cbe74dda2400bb0ea7a01b724735cbc3d9fe"
PATCH_OFFSET = 0x97928C
BEFORE = bytes.fromhex("0dc0a0e130d82de9")
AFTER = bytes.fromhex("0000a0e31eff2fe1")  # mov r0,#0; bx lr
XZ_MAGIC = b"\xfd7zXZ\x00"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def extract_kernel(data: bytes) -> bytes:
    start = 0
    while (offset := data.find(XZ_MAGIC, start)) >= 0:
        start = offset + 1
        try:
            decoder = lzma.LZMADecompressor()
            raw = decoder.decompress(data[offset:])
        except lzma.LZMAError:
            continue
        if decoder.eof and digest(raw) == RAW_SHA256:
            return raw
    raise SystemExit("pinned ASMB-787 kernel XZ payload not found")


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit(f"usage: {sys.argv[0]} SOURCE_ZIMAGE OUTPUT_IMAGE")
    source = pathlib.Path(sys.argv[1]).read_bytes()
    if digest(source) != SOURCE_SHA256:
        raise SystemExit("refusing unknown ASMB-787 zImage")
    raw = bytearray(extract_kernel(source))
    if raw[PATCH_OFFSET : PATCH_OFFSET + len(BEFORE)] != BEFORE:
        raise SystemExit("ncsi_start_dev preimage mismatch")
    raw[PATCH_OFFSET : PATCH_OFFSET + len(AFTER)] = AFTER
    if digest(raw) != PATCHED_SHA256:
        raise SystemExit("patched ASMB-787 kernel hash mismatch")
    pathlib.Path(sys.argv[2]).write_bytes(raw)


if __name__ == "__main__":
    main()
