import socket,sys,time
s=socket.socket(socket.AF_INET,socket.SOCK_DGRAM); s.setsockopt(socket.SOL_SOCKET,socket.SO_REUSEADDR,1)
s.bind(('127.0.0.1',5555)); s.settimeout(1)
t0=time.time(); nc=0; oth=0; seen=set()
while time.time()-t0<75:
    try: d,a=s.recvfrom(65535)
    except socket.timeout: continue
    if len(d)<14: continue
    et=(d[12]<<8)|d[13]
    if et==0x88f8:
        nc+=1; cmd=d[18] if len(d)>18 else -1
        if cmd not in seen: seen.add(cmd); print(f"NCSI cmd=0x{cmd:02x} chan=0x{d[19]:02x} len={len(d)} {d[:24].hex()}",flush=True)
    else: oth+=1
print(f"DONE ncsi={nc} other={oth} cmds={sorted(hex(c) for c in seen)}",flush=True)
