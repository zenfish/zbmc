#!/usr/bin/env bash
# boot.sh — restore the Supermicro X14 warm snapshot (qemu -incoming) and resume the vCPU.
#
# Captured in qemu-x14-svc mode (scripted daemon bring-up, no systemd) whose network survives restore.
# CE0 NOR = -drive if=mtd; rootfs = eMMC on mmcblk0 (-drive if=sd,index=2). Pinned to qemu-system-arm 11.x.
set -u
_HERE="$(cd "$(dirname "$0")" && pwd)"; _REPO="$(cd "$_HERE/../.." && pwd)"
WD="${WD:-$_REPO/work/$(basename "$_HERE")}"
IP="${IP:-127.0.0.1}"
SSH_PORT="${SSH_PORT:-4022}"; HTTPS_PORT="${HTTPS_PORT:-4443}"; IPMI_PORT="${IPMI_PORT:-4623}"
for f in svc-snap-full-working.gz kernel.bin x14-noncsi.dtb initramfs-patched.bin x14-ce0-64m.img emmc.img; do
  [ -f "$WD/$f" ] || { echo "missing $WD/$f — run ./build.sh supermicro-x14 first"; exit 1; }
done
SOCK="$WD/rserial.sock"; QMP="$WD/rqmp.sock"; rm -f "$SOCK" "$QMP"
CONSOLE_LOG="${ZBMC_CONSOLE_LOG:-$WD/console-uart.log}"

qemu-system-arm -M ast2600-evb -m 1024 \
  -kernel "$WD/kernel.bin" -dtb "$WD/x14-noncsi.dtb" -initrd "$WD/initramfs-patched.bin" \
  -drive "file=$WD/x14-ce0-64m.img,format=raw,if=mtd,snapshot=on" \
  -drive "file=$WD/emmc.img,format=raw,if=sd,index=2,snapshot=on" \
  -display none \
  -net nic -net "user,hostfwd=tcp:$IP:$SSH_PORT-:22,hostfwd=tcp:$IP:$HTTPS_PORT-:443,hostfwd=udp:$IP:$IPMI_PORT-:623,hostname=x14bmc" \
  -chardev "socket,id=serial0,path=$SOCK,server=on,wait=off,logfile=$CONSOLE_LOG,logappend=off" \
  -serial chardev:serial0 -qmp "unix:$QMP,server,nowait" \
  -incoming "exec:gunzip -c < $WD/svc-snap-full-working.gz" \
  -append "console=ttyS4,115200n8 root=/dev/ram rw maxcpus=1 initcall_blacklist=ast2600_spitee_init,optee_driver_init qemu-x14-ramroot qemu-x14-svc loglevel=4" \
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
