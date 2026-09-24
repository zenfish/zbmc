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

SHELL_INITRAMFS_VERSION=18

mkdir -p "$WD"
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
  echo '[irmc-ipmi] LAN channel enabled; stale IPMI cache removed'
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
printf 'derived_initramfs_shell_sha256=%s\n' "$(sha256sum "$shell_initramfs" | awk '{print $1}')" >>"$WD/build-provenance.txt"
echo "Fujitsu iRMC S6 runtime ready in $WD"
