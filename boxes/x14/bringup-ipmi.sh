#!/bin/sh
# bringup-ipmi.sh — GUEST-side: bring up in-band + LAN IPMI on a fresh cold shell-mode boot.
#
# Runs INSIDE the X14 guest (delivered via socat/base64). Order matters — every prereq the
# channel layer + dbus need must exist BEFORE ipmid starts, else ipmid's boost::interprocess
# channel mutex throws and Get Channel Auth Caps returns 0xCC forever.
#
# Correct order:  machine-id -> /dev/shm tmpfs -> /run/ipmi + /var/lib/ipmi -> pristine dbus
#                 -> object mapper -> ONE ipmid -> eth0 up -> ONE netipmid.
# Kills use /proc cmdline scan, NOT busybox `pkill -x` (which silently no-ops and stacks dups).
set +e

kill_by_cmd() {  # $1 = substring to match in /proc/*/cmdline
  for p in $(ls /proc 2>/dev/null | grep -E '^[0-9]+$'); do
    c=$(tr '\0' ' ' </proc/$p/cmdline 2>/dev/null)
    case "$c" in *"$1"*) kill -9 "$p" 2>/dev/null ;; esac
  done
}

echo "== prereqs =="
[ -s /etc/machine-id ] || dbus-uuidgen > /etc/machine-id
cat /etc/machine-id
mountpoint -q /dev/shm || { mkdir -p /dev/shm; mount -t tmpfs tmpfs /dev/shm && echo "shm:mounted"; }
mkdir -p /run/ipmi /var/lib/ipmi /run/dbus /var/run/dbus

echo "== pristine dbus =="
kill_by_cmd dbus-daemon; sleep 1
rm -f /run/dbus/pid /var/run/dbus/pid /run/dbus/system_bus_socket
setsid sh -c 'exec dbus-daemon --system --nofork --nopidfile' >/tmp/dbus.log 2>&1 &
sleep 3
[ -S /run/dbus/system_bus_socket ] && echo "dbus:UP" || echo "dbus:DOWN"

echo "== object mapper =="
kill_by_cmd mapperx; sleep 1
setsid sh -c 'exec mapperx' >/tmp/mapperx.log 2>&1 &
sleep 3

echo "== ipmid (single, clean) =="
kill_by_cmd /usr/bin/ipmid; kill_by_cmd " ipmid"; sleep 2
rm -f /dev/shm/*ipmi* /dev/shm/sem.*ipmi* /var/lib/ipmi/ipmi_channel_mutex* 2>/dev/null
setsid sh -c 'exec ipmid' >/tmp/ipmid.log 2>&1 &
sleep 9
n=$(for p in $(ls /proc|grep -E '^[0-9]+$'); do c=$(tr '\0' ' ' </proc/$p/cmdline 2>/dev/null); case "$c" in *ipmid*) case "$c" in *netipmid*) ;; *) echo x;; esac;; esac; done | wc -l)
echo "ipmid_count=$n"
grep -qa terminate /tmp/ipmid.log && echo "ipmid:TERMINATE" || echo "ipmid:NO_TERMINATE"

echo "== eth0 up =="
ip addr add 10.0.2.15/24 dev eth0 2>/dev/null
ip link set eth0 up
ip -4 -o addr show eth0 | tr -s ' '

echo "== netipmid (single) =="
kill_by_cmd netipmid; sleep 2
setsid sh -c 'exec /usr/bin/netipmid -c eth0' >/tmp/netipmid.log 2>&1 &
sleep 4
echo "623_holder:"; fuser 623/udp 2>&1
echo "== READY =="
