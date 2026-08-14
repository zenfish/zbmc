import subprocess,sys
H="-I lanplus -H 127.0.0.1 -p 5623 -U admin -P superuser".split()
def raw(*b):
    cmd=["ipmitool"]+H+["raw"]+[hex(x) for x in b]
    try:
        r=subprocess.run(cmd,capture_output=True,text=True,timeout=25)
        if r.returncode!=0: return None
        return [int(x,16) for x in r.stdout.split()]
    except Exception: return None
# names for standard NetFns
NF={0x00:"Chassis",0x04:"Sensor/Event",0x06:"App",0x08:"Firmware",0x0a:"Storage",0x0c:"Transport",
    0x2c:"Group(DCMI/HPM)",0x2e:"OEM-Group(IANA)",0x30:"OEM(AMI 0x30)",0x32:"OEM/WCS 0x32",
    0x34:"OEM 0x34",0x36:"OEM/WCS 0x36",0x38:"OEM/WCS 0x38",0x3a:"OEM 0x3a",0x3c:"OEM 0x3c",0x3e:"OEM 0x3e",0x02:"Bridge"}
print("NetFn  Name                 SupportedCmds")
for nf in range(0,0x40,2):
    bm=raw(0x06,0x0a,0x0e,nf,0x00)
    if not bm or len(bm)<16: continue
    cmds=[i*8+b for i,byte in enumerate(bm[:16]) for b in range(8) if byte>>b&1]
    if not cmds: continue
    name=NF.get(nf,f"NetFn 0x{nf:02x}")
    print(f"0x{nf:02x}   {name:20s} ({len(cmds):2d}) "+" ".join(f"{c:#04x}" for c in cmds))
