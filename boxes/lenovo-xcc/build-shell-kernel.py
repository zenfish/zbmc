#!/usr/bin/env python3
"""Build the emulator-only Lenovo XCC serial-shell kernel."""

from __future__ import annotations

import gzip
import hashlib
from pathlib import Path
import struct
import subprocess
import sys
import zlib


SOURCE_SHA256 = "809502472131dc103f2be2d4445f1ca8521dfdb13adba0fb1180cb037b382eac"
SOURCE_SIZE = 18_121_440
LZOP_OFFSET = 21_833
APPENDED_TAIL_OFFSET = 17_699_016
PAYLOAD_SIZE = 28_784_140
INITRAMFS_OFFSET = 21_504_264
LZOP_MAGIC = b"\x89LZO\x00\r\n\x1a\n"

SHELL_HOOK = """            cat > /xcc-diag-getty <<'ZBMC_EOF'
#!/bin/sh
while [ ! -e /etc/this-platform ]; do sleep 1; done
exec /sbin/getty -n -l /bin/bash 115200 ttyS4
ZBMC_EOF
            chmod 755 /xcc-diag-getty
            if mount --bind /xcc-diag-getty /rootfs/etc/scripts/rfs.getty; then
                echo XCC_DIAG_SHELL_BOUND > /dev/console
            else
                echo XCC_DIAG_SHELL_FAILED > /dev/console
            fi
"""
SWITCH_ROOT = """            # do switchroot, spawning init
            exec /sbin/switch_root -c /dev/ttyS4 /rootfs /sbin/init 3
"""


def u32(data: bytes, offset: int) -> int:
    return struct.unpack_from(">I", data, offset)[0]


def parse_lzop(data: bytes) -> tuple[bytes, list[tuple[int, int, bytes]], bytes]:
    if not data.startswith(LZOP_MAGIC):
        raise ValueError("missing LZOP header")

    version = struct.unpack_from(">H", data, 9)[0]
    pos = 15  # magic plus version, library version, required version
    pos += 2  # method and level
    flags = u32(data, pos)
    pos += 4
    if flags & 0x00000800:  # filter id
        pos += 4
    pos += 8  # mode and low mtime
    if version >= 0x0940:
        pos += 4  # high mtime
    name_length = data[pos]
    pos += 1 + name_length + 4  # filename and header checksum
    header = data[:pos]

    blocks: list[tuple[int, int, bytes]] = []
    while True:
        start = pos
        uncompressed_size = u32(data, pos)
        pos += 4
        if uncompressed_size == 0:
            return header, blocks, data[start:pos]
        compressed_size = u32(data, pos)
        pos += 4
        if flags & 0x00000001 or flags & 0x00000100:
            pos += 4
        if compressed_size < uncompressed_size:
            if flags & 0x00000002 or flags & 0x00000200:
                pos += 4
        pos += compressed_size
        blocks.append((uncompressed_size, compressed_size, data[start:pos]))


def run(command: list[str], *, data: bytes) -> bytes:
    return subprocess.run(
        command,
        input=data,
        stdout=subprocess.PIPE,
        check=True,
    ).stdout


def patch_archive(archive: bytes) -> bytes:
    output = bytearray()
    offset = 0
    patched = 0
    while True:
        header = bytearray(archive[offset : offset + 110])
        if header[:6] != b"070701":
            raise ValueError(f"invalid newc header at {offset}")
        fields = [int(header[6 + index * 8 : 14 + index * 8], 16) for index in range(13)]
        file_size = fields[6]
        name_size = fields[11]
        name_start = offset + 110
        name_end = name_start + name_size
        name_field = archive[name_start:name_end]
        if not name_field.endswith(b"\0"):
            raise ValueError("unterminated newc filename")
        name = name_field[:-1].decode()
        data_start = (name_end + 3) & ~3
        data_end = data_start + file_size
        contents = archive[data_start:data_end]

        if name.removeprefix("./") == "bin/init-xcc":
            text = contents.decode()
            if text.count(SWITCH_ROOT) != 1:
                raise ValueError("unexpected init-xcc switch_root contract")
            contents = text.replace(SWITCH_ROOT, SHELL_HOOK + SWITCH_ROOT).encode()
            header[54:62] = f"{len(contents):08x}".encode()
            patched += 1

        output.extend(header)
        output.extend(name_field)
        output.extend(bytes((-len(output)) % 4))
        output.extend(contents)
        output.extend(bytes((-len(output)) % 4))
        offset = (data_end + 3) & ~3
        if name == "TRAILER!!!":
            break

    if patched != 1:
        raise ValueError(f"expected one init-xcc entry, patched {patched}")
    output.extend(bytes((-len(output)) % 512))
    return bytes(output)


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit(f"usage: {sys.argv[0]} SOURCE.zImage OUTPUT.zImage")
    source_path, output_path = map(Path, sys.argv[1:])
    source = source_path.read_bytes()
    if len(source) != SOURCE_SIZE or hashlib.sha256(source).hexdigest() != SOURCE_SHA256:
        raise SystemExit("unexpected Lenovo source kernel")

    source_member = source[LZOP_OFFSET:APPENDED_TAIL_OFFSET]
    source_header, source_blocks, source_end = parse_lzop(source_member)
    source_member_length = len(source_header) + sum(len(block[2]) for block in source_blocks) + len(source_end)
    source_payload = run(["lzop", "-d", "-c"], data=source_member[:source_member_length])
    if len(source_payload) != PAYLOAD_SIZE:
        raise SystemExit("unexpected decompressed kernel size")

    compressed_archive = source_payload[INITRAMFS_OFFSET:]
    inflater = zlib.decompressobj(16 + zlib.MAX_WBITS)
    archive = inflater.decompress(compressed_archive) + inflater.flush()
    if not inflater.eof or len(archive) == 0:
        raise SystemExit("embedded initramfs is not a complete gzip member")
    consumed = len(compressed_archive) - len(inflater.unused_data)
    padding = 0
    while consumed + padding < len(compressed_archive) and compressed_archive[consumed + padding] == 0:
        padding += 1
    if padding == 0:
        raise SystemExit("embedded initramfs has no replacement padding")

    patched_archive = patch_archive(archive)
    patched_gzip = gzip.compress(patched_archive, compresslevel=9, mtime=0)
    capacity = consumed + padding
    if len(patched_gzip) > capacity:
        raise SystemExit("patched initramfs exceeds its fixed kernel region")
    patched_payload = (
        source_payload[:INITRAMFS_OFFSET]
        + patched_gzip
        + bytes(capacity - len(patched_gzip))
        + source_payload[INITRAMFS_OFFSET + capacity :]
    )

    candidate_member = run(["lzop", "-9", "-c"], data=patched_payload)
    _, candidate_blocks, _ = parse_lzop(candidate_member)
    if [block[0] for block in candidate_blocks] != [block[0] for block in source_blocks]:
        raise SystemExit("LZOP block layout changed")

    block_splice = bytearray(source_header)
    changed = 0
    offset = 0
    for source_block, candidate_block in zip(source_blocks, candidate_blocks, strict=True):
        size = source_block[0]
        if source_payload[offset : offset + size] == patched_payload[offset : offset + size]:
            block_splice.extend(source_block[2])
        else:
            block_splice.extend(candidate_block[2])
            changed += 1
        offset += size
    block_splice.extend(source_end)
    if LZOP_OFFSET + len(block_splice) > APPENDED_TAIL_OFFSET:
        raise SystemExit("patched LZOP member overlaps appended FDTs")

    output = (
        source[:LZOP_OFFSET]
        + block_splice
        + bytes(APPENDED_TAIL_OFFSET - LZOP_OFFSET - len(block_splice))
        + source[APPENDED_TAIL_OFFSET:]
    )
    if len(output) != SOURCE_SIZE or output[APPENDED_TAIL_OFFSET:] != source[APPENDED_TAIL_OFFSET:]:
        raise SystemExit("derived kernel layout changed")
    output_path.write_bytes(output)
    print(
        f"{hashlib.sha256(output).hexdigest()}  {output_path} "
        f"({changed}/{len(source_blocks)} LZOP blocks replaced)"
    )


if __name__ == "__main__":
    main()
