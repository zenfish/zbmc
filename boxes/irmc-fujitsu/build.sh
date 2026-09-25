#!/usr/bin/env bash
# zbmc:turnkey - fetch the verified iRMC S6 cold-boot artifact set.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
WD="${1:-${WD:-$ROOT/work/irmc-fujitsu}}"
MIRROR=https://git.trouble.org/zbmc/irmc-fujitsu

files=(
  'kernel.bin|e139d58349922e59b763d5d1824e8fb60865524c206dda3b975769d5c4641df3'
  'system-patched.dtb|877bcd44fd590e800035ac221d386fc6908cb20ddcc575708ad1558bec758592'
  'initramfs.cpio.gz|aed0ce8eb706180b21e798acad707d26f2e7a9e5d8d6f5933ec3ad7f2f13ad14'
  'flash64.img|e029ad09372a37c400b30446701440f905a855042174d3222e542261acbb152c'
  'rootfs-sd.img|4b9cea861e4c71ce1d0c71d1b8692705e02305eda7eeba4cd322946ea9524d78'
)

SHELL_INITRAMFS_VERSION=21

mkdir -p "$WD"
WD="$(cd "$WD" && pwd)"
for row in "${files[@]}"; do
  IFS='|' read -r file expected <<<"$row"
  if [ ! -f "$WD/$file" ] || [ "$(sha256sum "$WD/$file" | awk '{print $1}')" != "$expected" ]; then
    curl -fL --retry 2 -o "$WD/$file.part" "$MIRROR/$file"
    [ "$(sha256sum "$WD/$file.part" | awk '{print $1}')" = "$expected" ] || {
      echo "SHA-256 mismatch: $file" >&2
      exit 1
    }
    mv "$WD/$file.part" "$WD/$file"
  fi
done

redfish_dtb="$WD/system-redfish.dtb"
redfish_dtb_stamp="$WD/.system-redfish-version"
REDFISH_DTB_VERSION=1
if [ ! -f "$redfish_dtb" ] || [ "$WD/system-patched.dtb" -nt "$redfish_dtb" ] ||
   [ "$(cat "$redfish_dtb_stamp" 2>/dev/null)" != "$REDFISH_DTB_VERSION" ]; then
  command -v fdtput >/dev/null || { echo "missing tool: fdtput" >&2; exit 1; }
  cp "$WD/system-patched.dtb" "$redfish_dtb.part"
  fdtput -t s "$redfish_dtb.part" /ahb/spi@1e620000/flash@1 status okay
  fdtput -t x "$redfish_dtb.part" /ahb/mtdconcat@0 devices 5 6
  fdtput -t s "$redfish_dtb.part" /ahb/mtdconcat@0/partitions compatible ami,spx-fmh
  mv "$redfish_dtb.part" "$redfish_dtb"
  printf '%s\n' "$REDFISH_DTB_VERSION" >"$redfish_dtb_stamp"
fi

shell_initramfs="$WD/initramfs-shell.cpio.gz"
shell_stamp="$WD/.initramfs-shell-version"
if [ ! -f "$shell_initramfs" ] || [ "$WD/initramfs.cpio.gz" -nt "$shell_initramfs" ] ||
   [ "$(cat "$shell_stamp" 2>/dev/null)" != "$SHELL_INITRAMFS_VERSION" ]; then
  for tool in cpio gzip python3; do
    command -v "$tool" >/dev/null || { echo "missing tool: $tool" >&2; exit 1; }
  done
  shell_tree=$(mktemp -d)
  trap 'rm -rf "$shell_tree"' EXIT
  (cd "$shell_tree" && gzip -dc "$WD/initramfs.cpio.gz" | cpio -idm --quiet)
  dd if="$WD/flash64.img" of="$shell_tree/platform.sqsh" \
    bs=65536 skip=574 count=4 status=none
  [ "$(dd if="$shell_tree/platform.sqsh" bs=1 count=4 status=none | od -An -tx1 | tr -d ' \n')" = 68737173 ] || {
    echo "platform image does not begin with SquashFS magic" >&2
    exit 1
  }
  python3 - "$shell_tree/init" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text()
marker = "busybox mount --move /proc /newroot/proc\n"
addition = """zbmc_ip=''
zbmc_gateway=''
for arg in $(busybox cat /proc/cmdline); do
  case "$arg" in
    zbmc_ip=*) zbmc_ip=${arg#zbmc_ip=} ;;
    zbmc_gateway=*) zbmc_gateway=${arg#zbmc_gateway=} ;;
  esac
done
if busybox grep -qw irmc_redfish /proc/cmdline; then
  busybox mkdir -p /newroot/usr/local/platform
  busybox mount -t squashfs -o loop,ro /platform.sqsh /newroot/usr/local/platform \\
    && busybox echo '[irmc-init] embedded platform SquashFS mounted' \\
    || { busybox echo '[irmc-init] embedded platform SquashFS mount FAILED'; exec busybox sh; }
fi
if [ -n "$zbmc_ip" ]; then
  busybox ifconfig eth0 "$zbmc_ip" netmask 255.0.0.0 up
  [ -z "$zbmc_gateway" ] || busybox route add default gw "$zbmc_gateway" dev eth0
  busybox echo "ZBMC_TAP_NETWORK_READY $zbmc_ip"
fi
if busybox grep -qw irmc_diag_shell /proc/cmdline; then
  busybox echo '#!/bin/sh' > /diag-shell
  busybox echo 'exec /bin/sh -i' >> /diag-shell
  busybox chmod 0755 /diag-shell
  busybox mount --bind /diag-shell /newroot/usr/local/bin/remman \\
    && busybox echo "[irmc-init] diagnostic shell enabled"
fi
if busybox grep -qw irmc_diag_root /proc/cmdline; then
  busybox sed 's|^co:2345789:respawn:.*|co:2345789:respawn:/sbin/getty -n -l /usr/local/bin/remman -L console 38400 vt100|' \\
    /newroot/etc/inittab > /diag-inittab
  busybox mount --bind /diag-inittab /newroot/etc/inittab \\
    && busybox echo "[irmc-init] unauthenticated root console enabled"
fi
if busybox grep -qw irmc_diag_ipmi /proc/cmdline; then
  busybox cat > /ipmistack.ipmi <<'EOF'
#!/bin/sh
irmc_ipmi_prep()
{
  lan=/conf/BMC1/LanIfccfg.ini
  kcs=/conf/BMC1/lan_kcs.ini
  # LanIfccfg maps IPMI channel 2/eth0 to zero-based LAN object 0 (LANConfig1).
  lancfg=/conf/BMC1/lancfg0.ini
  mkdir -p /conf/BMC1
  if [ ! -f "$lan" ]; then
    cat > "$lan" <<'CFG'
[LANIfcConfig/LanIfcConfig/0]
Chnum=2
ifname=eth0
Enabled=1
Up_Status=1
Ethindex=0
Chtype=1

[LANIfcConfig/LanIfcConfig/3]
ifname=usb0
Ethindex=2
Up_Status=0
Chnum=7
Enabled=0
Chtype=3

[LANIfcConfig/LanIfcConfig/2]
Chtype=1
Enabled=0
ifname=bond0
Chnum=2
Ethindex=0
Up_Status=0
CFG
  fi
  if [ ! -f "$kcs" ]; then
    cat > "$kcs" <<'CFG'
[Dynamic_IFC_Support_Cfg]
AMI_DYNAMIC_KCS_IFC_SUPPORT=1
AMI_DYNAMIC_LAN_IFC_SUPPORT=1
CFG
  fi

  static_ip=
  static_gateway=
  for arg in $(cat /proc/cmdline); do
    case "$arg" in
      zbmc_ip=*) static_ip=${arg#zbmc_ip=} ;;
      zbmc_gateway=*) static_gateway=${arg#zbmc_gateway=} ;;
    esac
  done
  old_ifs=$IFS
  IFS=.
  set -- $static_ip
  IFS=$old_ifs
  [ "$#" -eq 4 ] || { echo '[irmc-ipmi] invalid or missing zbmc_ip'; return 1; }
  ip0=$1 ip1=$2 ip2=$3 ip3=$4
  IFS=.
  set -- $static_gateway
  IFS=$old_ifs
  [ "$#" -eq 4 ] || { echo '[irmc-ipmi] invalid or missing zbmc_gateway'; return 1; }
  gw0=$1 gw1=$2 gw2=$3 gw3=$4

  if [ ! -f "$lancfg" ]; then
    cat > "$lancfg" <<CFG
[LANConfgParams]
IPv4_Enable=1
IPv6_Enable=0
IPAddrSrc=1
IPAddr/0=$ip0
IPAddr/1=$ip1
IPAddr/2=$ip2
IPAddr/3=$ip3
SubNetMask/0=255
SubNetMask/1=0
SubNetMask/2=0
SubNetMask/3=0
DefaultGatewayIPAddr/0=$gw0
DefaultGatewayIPAddr/1=$gw1
DefaultGatewayIPAddr/2=$gw2
DefaultGatewayIPAddr/3=$gw3
CFG
  else
    awk -v ip0="$ip0" -v ip1="$ip1" -v ip2="$ip2" -v ip3="$ip3" \
        -v gw0="$gw0" -v gw1="$gw1" -v gw2="$gw2" -v gw3="$gw3" '
      /^\[LANConfgParams\]$/ { section = 1 }
      /^\[/ && $0 != "[LANConfgParams]" { section = 0 }
      section && /^IPv4_Enable=/ { print "IPv4_Enable=1"; next }
      section && /^IPv6_Enable=/ { print "IPv6_Enable=0"; next }
      section && /^IPAddrSrc=/ { print "IPAddrSrc=1"; next }
      section && /^IPAddr\/0=/ { print "IPAddr/0=" ip0; next }
      section && /^IPAddr\/1=/ { print "IPAddr/1=" ip1; next }
      section && /^IPAddr\/2=/ { print "IPAddr/2=" ip2; next }
      section && /^IPAddr\/3=/ { print "IPAddr/3=" ip3; next }
      section && /^SubNetMask\/0=/ { print "SubNetMask/0=255"; next }
      section && /^SubNetMask\/[123]=/ { print substr($0, 1, index($0, "=")) "0"; next }
      section && /^DefaultGatewayIPAddr\/0=/ { print "DefaultGatewayIPAddr/0=" gw0; next }
      section && /^DefaultGatewayIPAddr\/1=/ { print "DefaultGatewayIPAddr/1=" gw1; next }
      section && /^DefaultGatewayIPAddr\/2=/ { print "DefaultGatewayIPAddr/2=" gw2; next }
      section && /^DefaultGatewayIPAddr\/3=/ { print "DefaultGatewayIPAddr/3=" gw3; next }
      { print }
    ' "$lancfg" > "$lancfg.zbmc" || return 1
    mv "$lancfg.zbmc" "$lancfg" || return 1
    grep -q '^IPv4_Enable=' "$lancfg" || echo 'IPv4_Enable=1' >> "$lancfg"
    grep -q '^IPv6_Enable=' "$lancfg" || echo 'IPv6_Enable=0' >> "$lancfg"
  fi

  awk '
    /^\\[LANIfcConfig\\/LanIfcConfig\\/0\\]$/ { section = 1 }
    /^\\[LANIfcConfig\\/LanIfcConfig\\/[123]\\]$/ { section = 0 }
    section && /^Enabled=0$/ { print "Enabled=1"; next }
    section && /^Up_Status=0$/ { print "Up_Status=1"; next }
    { print }
  ' "$lan" > "$lan.zbmc" || return 1
  mv "$lan.zbmc" "$lan" || return 1

  sed 's/^AMI_DYNAMIC_LAN_IFC_SUPPORT=.*/AMI_DYNAMIC_LAN_IFC_SUPPORT=1/' \
    "$kcs" > "$kcs.zbmc" || return 1
  grep -q '^AMI_DYNAMIC_LAN_IFC_SUPPORT=1$' "$kcs.zbmc" || return 1
  mv "$kcs.zbmc" "$kcs" || return 1

  rm -f /tmp/BMC1/IPMIConfig.dat
  echo "[irmc-ipmi] LAN channel enabled with static IPv4 $static_ip/8 and IPv6 disabled; stale IPMI cache removed"
}

irmc_ipmi_trace_listener()
{
  grep -qw irmc_trace_ipmi /proc/cmdline || return 0
  (
    previous=unset
    samples=0
    while [ "$samples" -lt 6000 ]; do
      IFS=' ' read -r uptime ignored </proc/uptime
      udp6=absent
      while read -r slot local remote state queues timers retransmit uid timeout inode rest; do
        case "$local" in
          *:026F) udp6="present inode=$inode state=$state" ;;
        esac
      done </proc/net/udp6
      tcp6=absent
      while read -r slot local remote state queues timers retransmit uid timeout inode rest; do
        case "$local" in
          *:026F) tcp6="present inode=$inode state=$state" ;;
        esac
      done </proc/net/tcp6
      current="$udp6|$tcp6"
      if [ "$current" != "$previous" ]; then
        echo "ZBMC_IPMI_LISTENER uptime=$uptime udp6=[$udp6] tcp6=[$tcp6]"
        previous=$current
      fi
      samples=$((samples + 1))
      sleep 0.1
    done
  ) >/dev/console 2>&1 &
  echo "[irmc-ipmi] listener tracer started as PID $!"
}
EOF
  busybox sed 's@^\\([[:space:]]*\\)\\(/usr/local/bin/IPMIMain --daemonize --reg-with-procmgr\\)$@\\1irmc_ipmi_prep || exit 1; irmc_ipmi_trace_listener; \\2@' \
    /newroot/etc/init.d/ipmistack >> /ipmistack.ipmi
  busybox chmod 0755 /ipmistack.ipmi
  busybox mount --bind /ipmistack.ipmi /newroot/etc/init.d/ipmistack \
    && busybox echo '[irmc-init] IPMI LAN pre-start hook installed'
fi
"""
if text.count(marker) != 1:
    raise SystemExit("unexpected base initramfs /init")
path.write_text(text.replace(marker, addition + marker))
PY
  (cd "$shell_tree" && find . -print0 | sort -z |
    cpio --null -o -H newc --quiet | gzip -1) >"$shell_initramfs.part"
  mv "$shell_initramfs.part" "$shell_initramfs"
  printf '%s\n' "$SHELL_INITRAMFS_VERSION" >"$shell_stamp"
  rm -rf "$shell_tree"
  trap - EXIT
fi

printf 'source=Fujitsu iRMC S6 RX2540 M7 02.63S / SDR 03.67\n' >"$WD/build-provenance.txt"
printf 'source_flash_sha256=89dd885694ebc86af29e900f04e22d4b63998ac35055e18c86ba96d6016ce2ed\n' >>"$WD/build-provenance.txt"
printf '%s\n' "${files[@]}" >>"$WD/build-provenance.txt"
printf 'derived_redfish_dtb_sha256=%s\n' "$(sha256sum "$redfish_dtb" | awk '{print $1}')" >>"$WD/build-provenance.txt"
printf 'embedded_platform_sha256=%s\n' "$(dd if="$WD/flash64.img" bs=65536 skip=574 count=4 status=none | sha256sum | awk '{print $1}')" >>"$WD/build-provenance.txt"
printf 'derived_initramfs_shell_sha256=%s\n' "$(sha256sum "$shell_initramfs" | awk '{print $1}')" >>"$WD/build-provenance.txt"
echo "Fujitsu iRMC S6 runtime ready in $WD"
