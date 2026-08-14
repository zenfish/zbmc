#!/bin/sh
# net-selfheal.sh — keep the usb-net (slirp) interface alive across checkpoint save/restore.
# WHY: with the migratable-usb-net qemu patch, usb-net is NOT unplugged for the checkpoint, so the
# restored guest keeps its usb0 iface + IP. BUT the in-flight USB bulk-IN (RX) request the guest had
# outstanding at save time is lost on restore -> RX deadlocks (guest waits on a URB the device model
# forgot; slirp logs "Failed to send packet"). A link bounce (ip link down/up) makes the guest's
# usbnet driver tear down and RESUBMIT its RX URBs -> RX works again. This watchdog runs from boot
# (frozen into the checkpoint); on restore it sees the gateway unreachable and bounces the iface.
# Detection is ping-based (RX-stall = no ping reply even though the iface is up + configured).
# LOG: /dev/console (visible on the host serial log even with no net).
IP=10.0.2.15/24; GW=10.0.2.2
say(){ echo "net-selfheal: $*" > /dev/console; }
cdc_iface(){
  for f in /sys/class/net/*; do
    [ -e "$f/device/driver" ] || continue
    case "$(basename "$(readlink "$f/device/driver")")" in
      cdc_ether|usbnet|cdc_ncm|rndis_host) basename "$f"; return;;
    esac
  done
}
config(){ i="$1"; ip link set "$i" up 2>/dev/null
  ip -o -4 addr show "$i" 2>/dev/null | grep -q "${IP%/*}" || ip addr add "$IP" dev "$i" 2>/dev/null
  ip route show default 2>/dev/null | grep -q "$GW" || ip route add default via "$GW" dev "$i" 2>/dev/null; }
alive(){ ping -c1 -W2 "$GW" >/dev/null 2>&1; }

say "started (ping $GW; bounce cdc iface on RX-stall)"
while :; do
  i=$(cdc_iface)
  if [ -n "$i" ]; then
    config "$i"
    if ! alive; then
      say "gw unreachable -> bounce $i (resubmit RX URBs)"
      ip link set "$i" down 2>/dev/null; sleep 1
      ip link set "$i" up   2>/dev/null; sleep 2
      config "$i"
      alive && say "$i recovered ($GW reachable)"
    fi
  fi
  sleep 5
done
