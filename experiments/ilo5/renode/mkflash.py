#!/usr/bin/env python3
# mkflash.py - build a GXP bootblock flash image + manifest that bootblock accepts.
# Validated live (iter 22): find_block returns the block (ID matched @+0x2a, header CRC ok).
# Block format (RE'd from bootblock validators, all CRC-32/XOR, no keys):
#   +0x20 magic 0x4edd411a ; +0x24 header word (low byte 2=>2KB) ; +0x2a u16 block ID
#   +0x5c CRC32(block[0..0x58]+block[0x60..0x100]) ; last word = block[+0x24] ^ magic
#   +0x3c/0x40/0x44 = payload base/len/CRC (next layer, for real stage data)
# Manifest @0xFFFF02A8 (find_block idtab): u16 count, then u16 wanted IDs.
import struct, zlib, sys
MAGIC = 0x4edd411a
def make_block(block_id, header_word=2, size=0x800, payload=b""):
    b = bytearray(size)
    struct.pack_into("<I", b, 0x20, MAGIC)
    struct.pack_into("<I", b, 0x24, header_word)
    struct.pack_into("<H", b, 0x2a, block_id)
    struct.pack_into("<I", b, size-4, header_word ^ MAGIC)
    b[0x100:0x100+len(payload)] = payload[:size-0x104]
    struct.pack_into("<I", b, 0x5c, zlib.crc32(bytes(b[0:0x58])+bytes(b[0x60:0x100])) & 0xffffffff)
    return bytes(b)
def make_manifest(ids):
    m = bytearray(0x10000)                 # region @0xFFFF0000; manifest at offset 0x2a8
    struct.pack_into("<H", m, 0x2a8, len(ids)+1)   # count (index 0 is the count itself)
    for i, x in enumerate(ids):
        struct.pack_into("<H", m, 0x2aa + i*2, x)
    return bytes(m)
if __name__ == "__main__":
    ID = 0x1234
    flash = bytearray(make_block(ID)) + b"\x00"*(0x100000-0x800)
    open("/tmp/blk.bin","wb").write(bytes(flash))
    open("/tmp/manifest.bin","wb").write(make_manifest([ID]))
    print(f"flash block id=0x{ID:x} + manifest -> /tmp/blk.bin, /tmp/manifest.bin")
