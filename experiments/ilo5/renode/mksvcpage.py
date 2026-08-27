#!/usr/bin/env python3
# mksvcpage.py - bootblock's 0xFFFF0000 service page + dispatcher @0xFFFF0024.
# bootloader1 calls services via `mov ip,#code; b ->ldr pc,[0x38]=0xFFFF0024`.
# Services decoded (live): 0x13=get-boot-mode(ret in fp), 0x16/0x18=putchar(r0), 0x23=newline,
#   0x1b-0x1f=PRINT INLINE STRING (the string follows the bl at lr; must print it AND return PAST it,
#   4-aligned -- else the CPU executes the string -> undefined instruction).
# CRITICAL: preserve fp (bootloader1 does `mov sp,fp; pop {..pc}`).
import struct, sys
sys.path.insert(0, __file__.rsplit("/",1)[0])
from mkflash import make_manifest
def make_service_page(manifest_ids=(0x1234,)):
    m = bytearray(make_manifest(list(manifest_ids)))
    disp = [
        0xe35c0013,  #24 cmp r12,#0x13
        0x03a0b000,  #28 moveq fp,#0
        0x012fff1e,  #2c bxeq lr
        0xe35c0016,  #30 cmp r12,#0x16
        0x0a000007,  #34 beq putc(0x58)
        0xe35c0018,  #38 cmp r12,#0x18
        0x0a000005,  #3c beq putc(0x58)
        0xe35c0023,  #40 cmp r12,#0x23
        0x0a000006,  #44 beq newline(0x64)
        0xe24c301b,  #48 sub r3,r12,#0x1b
        0xe3530004,  #4c cmp r3,#4
        0x9a000007,  #50 bls instr(0x74)
        0xe12fff1e,  #54 bx lr  (else: return, preserve all)
        0xe3a01103,  #58 putc: mov r1,#0xc0000000
        0xe5c100f0,  #5c strb r0,[r1,#0xf0]
        0xe12fff1e,  #60 bx lr
        0xe3a0000a,  #64 newline: mov r0,#0x0a
        0xe3a01103,  #68 mov r1,#0xc0000000
        0xe5c100f0,  #6c strb r0,[r1,#0xf0]
        0xe12fff1e,  #70 bx lr
        0xe3a01103,  #74 instr: mov r1,#0xc0000000
        0xe4de2001,  #78 isloop: ldrb r2,[lr],#1
        0xe3520000,  #7c cmp r2,#0
        0x0a000001,  #80 beq isdone(0x8c)
        0xe5c120f0,  #84 strb r2,[r1,#0xf0]
        0xeafffffa,  #88 b isloop(0x78)
        0xe28ee003,  #8c isdone: add lr,lr,#3
        0xe3cee003,  #90 bic lr,lr,#3
        0xe12fff1e,  #94 bx lr
    ]
    for i,instr in enumerate(disp):
        struct.pack_into("<I", m, 0x24+i*4, instr)
    return bytes(m)
if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "svcpage.bin"
    open(out,"wb").write(make_service_page())
    print(f"service page (inline-string dispatcher) -> {out}")
