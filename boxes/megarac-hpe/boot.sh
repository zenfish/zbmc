#!/usr/bin/env bash
# boot.sh — restore the HPE XD670 MegaRAC warm snapshot (qemu -incoming) and resume the vCPU.
#
# Resumes a state captured *past* the IPMIMain cold-boot SIGSEGV race, so IPMI 2.0 RMCP+ + authed Redfish
# are green on resume. Direct-kernel + the frozen NOR (as -drive if=mtd). Pinned to qemu-system-arm 11.x.
set -u
_HERE="$(cd "$(dirname "$0")" && pwd)"; _REPO="$(cd "$_HERE/../.." && pwd)"
WD="${WD:-$_REPO/work/$(basename "$_HERE")}"
IP="${IP:-127.0.0.1}"
SSH_PORT="${SSH_PORT:-5022}"; HTTPS_PORT="${HTTPS_PORT:-5443}"; IPMI_PORT="${IPMI_PORT:-5623}"
for f in kernel.Image dtb-a1.dtb rootfs.sqfs cray-snap-flash.bin cray-snap.gz; do
  [ -f "$WD/$f" ] || { echo "missing $WD/$f — run ./build.sh megarac-hpe first"; exit 1; }
done
SOCK="$WD/rserial.sock"; QMP="$WD/rqmp.sock"; rm -f "$SOCK" "$QMP"

qemu-system-arm -M ast2600-evb -m 1024 \
  -kernel "$WD/kernel.Image" -dtb "$WD/dtb-a1.dtb" -initrd "$WD/rootfs.sqfs" \
  -drive "file=$WD/cray-snap-flash.bin,format=raw,if=mtd,snapshot=on" \
  -display none \
  -net nic -net "user,hostfwd=tcp:$IP:$SSH_PORT-:22,hostfwd=tcp:$IP:$HTTPS_PORT-:443,hostfwd=udp:$IP:$IPMI_PORT-:623,hostname=megarac-hpe" \
  -serial "unix:$SOCK,server,nowait" -qmp "unix:$QMP,server,nowait" \
  -incoming "exec:gunzip -c < $WD/cray-snap.gz" \
  -append "console=ttyS4,115200n8 root=/dev/ram0 ro rootfstype=squashfs ramdisk_size=131072 ramdisk_blocksize=4096 mtdparts=1e620000.spi:1M(uboot),2M(conf),2M(bkupconf),1M(extlog),4M(www),-(root) maxcpus=1 rootwait" \
  > "$WD/svc.log" 2>&1 &
QP=$!

for i in $(seq 1 60); do [ -S "$QMP" ] && break; sleep 0.25; done
python3 - "$QMP" <<'PY' 2>/dev/null
import socket,sys,json,time
s=socket.socket(socket.AF_UNIX); s.connect(sys.argv[1]); f=s.makefile('rw')
def cmd(c): f.write(json.dumps(c)+"\r\n"); f.flush(); return json.loads(f.readline())
f.readline(); cmd({"execute":"qmp_capabilities"})
for _ in range(25):
    cmd({"execute":"cont"})
    if cmd({"execute":"query-status"}).get("return",{}).get("running"): break
    time.sleep(0.3)
PY
echo "$QP"
