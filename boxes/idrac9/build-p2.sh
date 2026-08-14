#!/usr/bin/env bash
# build-p2.sh — build the Phase-2 boot artifacts (patched kernel + single-CPU DTB).
# Needs boot/zImage + boot/base.dts from build.sh first.
set -euo pipefail; cd "$(dirname "$0")"

echo "[1/5] decompress zImage -> vmlinux.bin (XZ piggy)"
python3 - <<'PY'
import lzma
d=open('boot/zImage','rb').read()
off=[i for i in range(len(d)) if d[i:i+6]==b'\xfd7zXZ\x00']
for o in off:
    try:
        dec=lzma.LZMADecompressor(format=lzma.FORMAT_XZ); out=dec.decompress(d[o:])
        if len(out)>1_000_000: open('boot/vmlinux.bin','wb').write(out); print("  ok from %#x -> %d"%(o,len(out))); break
    except Exception: pass
PY

echo "[2/5] patch dm_bufio cleanup timer (NOP both queue_delayed_work_on sites)"
python3 scripts/patch-kernel.py

echo "[3/5] wrap patched Image as uImage (load/entry 0x8000, no compression)"
mkimage -A arm -O linux -T kernel -C none -a 0x8000 -e 0x8000 -n idrac9p \
  -d boot/vmlinux.patched.bin boot/uImage.patched >/dev/null

echo "[4/5] build Phase-2 DTB (disable aes,sha,pl310-L2,4x eth)"
python3 - <<'PY'
import re
s=open('boot/base.dts').read().split('\n'); out=[]; nodes={'aes@f0858000','sha@f085a000',
 'eth@f0802000','eth@f0804000','eth@f0825000','eth@f0826000','cache-controller@3fc000'}
cur=None; depth=0
for ln in s:
    m=re.match(r'\s*([A-Za-z0-9,._@-]+)\s*\{\s*$',ln)
    if m:
        depth+=1
        if m.group(1) in nodes: cur=(m.group(1),depth)
    if cur and 'status =' in ln: ln=re.sub(r'status = "[^"]*"','status = "disabled"',ln)
    if '}' in ln:
        # close: if node had no status, inject disabled before brace handled crudely below
        if cur and depth==cur[1]:
            # ensure a status was present; pl310 has none -> add
            cur=None
        depth-=1
    out.append(ln)
open('boot/p2.dts','w').write('\n'.join(out))
PY
# pl310 cache-controller has no status property; add one
python3 - <<'PY'
s=open('boot/p2.dts').read()
s=s.replace('cache-controller@3fc000 {','cache-controller@3fc000 {\n\t\t\tstatus = "disabled";',1)
open('boot/p2.dts','w').write(s)
PY
dtc -I dts -O dtb -o boot/p2.dtb boot/p2.dts 2>/dev/null

echo "[5/5] single-CPU variant (remove cpu@1)"
python3 - <<'PY'
import re
s=open('boot/p2.dts').read()
s=re.sub(r'\n\t\tcpu@1 \{.*?\n\t\t\};','',s,count=1,flags=re.S)
open('boot/p2uni.dts','w').write(s)
PY
dtc -I dts -O dtb -o boot/p2uni.dtb boot/p2uni.dts 2>/dev/null

echo "done: boot/{uImage.patched,p2.dtb,p2uni.dtb}. Build initramfs.p2.xz from init.p2.custom:"
echo "  rm -rf img/initrd2 && cp -a img/initrd img/initrd2 && cp init.p2.custom img/initrd2/init"
echo "  (cd img/initrd2 && find . | cpio -o -H newc 2>/dev/null | xz --check=crc32 -c) > boot/initramfs.p2.xz"
