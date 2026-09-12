#!/usr/bin/env python3
"""Shared ATEN AST2600 kernel-FIT carve + dtb patch helper for zbmc Supermicro boxes.

Carves the ATEN kernel FIT (d00dfeed) out of the raw 64 MiB NOR flash, extracts the
kernel zImage + its dtb, then patches the dtb: enables the FMC SPI-NOR controller
(spi@1e620000, shipped "disabled" on the eMMC-root ROT builds), injects a "rofs"
fixed-partition pointing at the real squashfs offset, and disables the OP-TEE node
(its secure-world SMC calls hang under qemu).

Usage:
  aten-carve.py <flash.bin> <workdir> --fit-off 0x130000 --rofs-off 0x630000 \
                --rofs-len 0x2900000 [--no-optee-disable]

Writes <workdir>/kernel.bin, <workdir>/fdt.dtb, <workdir>/fdt-patched.dtb.
"""
import sys, os, struct, argparse, subprocess, tempfile

def carve_fit(img, off):
    data = open(img, 'rb').read()
    assert struct.unpack('>I', data[off:off+4])[0] == 0xd00dfeed, \
        "no FIT magic at offset 0x%x" % off
    tot = struct.unpack('>I', data[off+4:off+8])[0]
    fit = data[off:off+tot]
    magic, totalsize, os_, ost, orv, ver, lcv, boot, ss, st = struct.unpack('>10I', fit[:40])
    blk = fit[os_:os_+st]; strs = fit[ost:ost+ss]
    def cstr(o):
        e = strs.index(b'\x00', o); return strs[o:e].decode()
    i = 0; stack = []; nodes = {}
    while i < len(blk):
        tag, = struct.unpack('>I', blk[i:i+4]); i += 4
        if tag == 1:
            e = blk.index(b'\x00', i); nm = blk[i:e].decode(); i = (e+1+3) & ~3; stack.append((nm, {}))
        elif tag == 2:
            nm, p = stack.pop(); nodes['/'.join(s[0] for s in stack) + '/' + nm] = p
        elif tag == 3:
            pl, no = struct.unpack('>II', blk[i:i+8]); i += 8; v = blk[i:i+pl]; i = (i+pl+3) & ~3
            stack[-1][1][cstr(no)] = v
        elif tag == 9:
            break
    # Node names vary by generation: '/images/kernel@1' (X13/H13S) or '/images/kernel@...'
    # with an fdt@aspeed-* sibling (X12/H13F). Match the image node that carries a 'data'
    # payload (its hash@N child shares the prefix but has no data).
    kn = next(k for k in nodes if k.startswith('/images/kernel') and 'data' in nodes[k])
    fn = next(k for k in nodes if k.startswith('/images/fdt') and 'data' in nodes[k])
    return nodes[kn]['data'], nodes[fn]['data']

def patch_dtb(dts, rofs_off, rofs_len, no_optee, inject_rofs=True):
    s = open(dts).read()
    # Enable the FMC controller (spi@1e620000) and flash@0. Brace-match the FMC node so
    # replacements stay inside it.
    fmc_start = s.index('spi@1e620000 {')
    d = 0; k = fmc_start
    while k < len(s):
        if s[k] == '{': d += 1
        elif s[k] == '}':
            d -= 1
            if d == 0: fmc_end = k; break
        k += 1
    fmc = s[fmc_start:fmc_end+1]
    fmc = fmc.replace('status = "disabled";', 'status = "okay";', 1)   # controller
    f0 = fmc.index('flash@0 {')
    d = 0; k = f0
    while k < len(fmc):
        if fmc[k] == '{': d += 1
        elif fmc[k] == '}':
            d -= 1
            if d == 0: f0_end = k; break
        k += 1
    blk = fmc[f0:f0_end].replace('status = "disabled";', 'status = "okay";', 1)
    if inject_rofs:
        number = 'rofs@%x' % rofs_off
        part = ('\t\t\t\t\t%s {\n'
                '\t\t\t\t\t\treg = <0x%x 0x%x>;\n'
                '\t\t\t\t\t\tlabel = "rofs";\n'
                '\t\t\t\t\t\tread-only;\n'
                '\t\t\t\t\t};\n' % (number, rofs_off, rofs_len))
        if 'partitions {' in blk:
            # A fixed-partitions node already exists (e.g. X13D's ipmifw_img map). Insert the
            # rofs partition after the node's property lines (compatible/#address-cells/
            # #size-cells) so it enumerates as the first partition — root=/dev/mtdblock0 then
            # resolves to the squashfs regardless of the shipping map.
            j = blk.index('partitions {')
            m = blk.index('#size-cells', j)
            # end of the #size-cells property line = start of the subnode region
            nl = blk.index('\n', m) + 1
            blk = blk[:nl] + part + blk[nl:]
        else:
            # No shipping map: splice a complete fixed-partitions node with a single "rofs"
            # (the eMMC ROT builds X13/H13S, whose dtb ships the FMC disabled). Inserted
            # BEFORE flash@0's closing brace; DTS requires properties to precede subnodes.
            blk += ('\t\t\t\tpartitions {\n'
                    '\t\t\t\t\tcompatible = "fixed-partitions";\n'
                    '\t\t\t\t\t#address-cells = <0x01>;\n'
                    '\t\t\t\t\t#size-cells = <0x01>;\n'
                    + part + '\t\t\t\t};\n\t\t\t')
    fmc = fmc[:f0] + blk + fmc[f0_end:]
    s = s[:fmc_start] + fmc + s[fmc_end+1:]
    # Disable the OP-TEE secure-world node (SMC calls hang / are unserviced under qemu).
    if not no_optee and 'compatible = "linaro,optee-tz";' in s:
        s = s.replace('compatible = "linaro,optee-tz";\n\t\t\tmethod = "smc";',
                      'compatible = "linaro,optee-tz";\n\t\t\tmethod = "smc";\n\t\t\tstatus = "disabled";', 1)
    return s

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('flash'); ap.add_argument('workdir')
    ap.add_argument('--fit-off', type=lambda x: int(x, 0), required=True)
    ap.add_argument('--rofs-off', type=lambda x: int(x, 0), default=0)
    ap.add_argument('--rofs-len', type=lambda x: int(x, 0), default=0)
    ap.add_argument('--no-optee-disable', action='store_true')
    a = ap.parse_args()
    os.makedirs(a.workdir, exist_ok=True)
    kern, dtb = carve_fit(a.flash, a.fit_off)
    kf = os.path.join(a.workdir, 'kernel.bin'); df = os.path.join(a.workdir, 'fdt.dtb')
    open(kf, 'wb').write(kern); open(df, 'wb').write(dtb)
    print("  carved kernel.bin (%d B) + fdt.dtb (%d B) @ fit 0x%x" % (len(kern), len(dtb), a.fit_off))
    with tempfile.TemporaryDirectory() as td:
        dts = os.path.join(td, 'fdt.dts'); pdts = os.path.join(td, 'fdt-patched.dts')
        pdtb = os.path.join(a.workdir, 'fdt-patched.dtb')
        # dtc warns (unit_address_*) on vendor DTS; -W no-unit_address_* keeps the output.
        subprocess.run(['dtc', '-I', 'dtb', '-O', 'dts', '-o', dts, df], check=True,
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        open(pdts, 'w').write(patch_dtb(dts, a.rofs_off, a.rofs_len, a.no_optee_disable,
                                        inject_rofs=(a.rofs_len > 0)))
        try:
            subprocess.run(['dtc', '-I', 'dts', '-O', 'dtb', '-o', pdtb, pdts], check=True,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError:
            sys.stderr.write("dtc failed; first error lines:\n")
            subprocess.run(['dtc', '-I', 'dts', '-O', 'dtb', '-o', pdtb, pdts])
            raise
    if a.rofs_len > 0:
        print("  patched fdt-patched.dtb (rofs@0x%x len 0x%x, FMC on, optee off)" % (a.rofs_off, a.rofs_len))
    else:
        print("  patched fdt-patched.dtb (FMC on, optee off; no rofs injection)")

if __name__ == '__main__':
    main()
