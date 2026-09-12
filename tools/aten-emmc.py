#!/usr/bin/env python3
"""Build a blank GPT eMMC image with named Linux-fs partitions (for ATEN AST2600 boxes).

The ATEN 00partition_check.sh mounts /dev/mmcblk0p<N> -> /nv, /nv1, /nv2 and, when the
mount fails, runs mkfs.ext4 on the device itself — so a blank GPT with the right partition
slots lets the guest format them on first boot. qemu attaches this at if=sd,index=2 (after
the 2 SD slots) which the non-removable sdc@1e750000 controller enumerates as mmcblk0.

Usage: aten-emmc.py <out.img> <size_mb> <name:size_mb> [<name:size_mb> ...]
  e.g. aten-emmc.py emmc.img 256 nv:100 nv1:100
Partition slot index = position in the list + 1 (first arg = p1, etc.). Supermicro ATEN
uses p5/p6/p7, so pad with small dummy leading entries if you need a specific slot.
"""
import sys, struct, zlib, uuid

SEC = 512
ENTRIES = 128
ENTRY_SZ = 128
PARR_SECS = ENTRIES * ENTRY_SZ // SEC
LINUX_FS = uuid.UUID('0FC63DAF-8483-4772-8E79-3D69D8477DE4')

def guid_le(u):
    b = u.bytes
    return b[3::-1] + b[5:3:-1] + b[7:5:-1] + b[8:]

def entry(tg, start, end, name):
    e = bytearray(ENTRY_SZ)
    e[0:16] = guid_le(tg); e[16:32] = guid_le(uuid.uuid4())
    struct.pack_into('<QQQ', e, 32, start, end, 0)
    nm = name.encode('utf-16-le')[:72]; e[56:56+len(nm)] = nm
    return bytes(e)

def hdr(cur, bak, fu, lu, parr, pcrc, dg):
    h = bytearray(92); h[0:8] = b'EFI PART'
    struct.pack_into('<III', h, 8, 0x00010000, 92, 0)
    struct.pack_into('<QQQQ', h, 24, cur, bak, fu, lu); h[56:72] = guid_le(dg)
    struct.pack_into('<QIII', h, 72, parr, ENTRIES, ENTRY_SZ, pcrc)
    struct.pack_into('<I', h, 16, zlib.crc32(bytes(h)) & 0xffffffff)
    return bytes(h)

def main():
    out = sys.argv[1]; size_mb = int(sys.argv[2])
    parts = []  # list of (slot_index_1based, name, size_mb)
    for spec in sys.argv[3:]:
        slot, name, sz = spec.split(':')
        parts.append((int(slot), name, int(sz)))
    TOTAL = size_mb * 1024 * 1024 // SEC
    fu = 2 + PARR_SECS; lu = TOTAL - 2 - PARR_SECS
    ents = bytearray(ENTRIES * ENTRY_SZ)
    cur_sec = 2048
    for slot, name, sz in sorted(parts):
        nsec = sz * 1024 * 1024 // SEC
        s = cur_sec; e = s + nsec - 1
        assert e < lu, "partition %s overflows disk" % name
        ents[(slot-1)*ENTRY_SZ:slot*ENTRY_SZ] = entry(LINUX_FS, s, e, name)
        cur_sec = e + 1
        print("  p%d = %-6s  %d MiB  (sectors %d-%d)" % (slot, name, sz, s, e))
    pcrc = zlib.crc32(bytes(ents)) & 0xffffffff; dg = uuid.uuid4()
    data = bytearray(TOTAL * SEC)
    mbr = bytearray(SEC); mbr[510:512] = b'\x55\xaa'
    pe = bytearray(16); pe[4] = 0xEE
    struct.pack_into('<I', pe, 8, 1); struct.pack_into('<I', pe, 12, min(TOTAL-1, 0xffffffff))
    mbr[446:462] = pe; data[0:SEC] = mbr
    data[SEC:SEC+92] = hdr(1, TOTAL-1, fu, lu, 2, pcrc, dg)
    data[2*SEC:2*SEC+len(ents)] = ents
    bak = TOTAL-1-PARR_SECS
    data[bak*SEC:bak*SEC+len(ents)] = ents
    data[(TOTAL-1)*SEC:(TOTAL-1)*SEC+92] = hdr(TOTAL-1, 1, fu, lu, bak, pcrc, dg)
    open(out, 'wb').write(data)
    print("  wrote %s (%d MiB)" % (out, size_mb))

if __name__ == '__main__':
    main()
