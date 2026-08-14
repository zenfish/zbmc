#!/usr/bin/env bash
# run-p2-net.sh — Phase 2 boot: iDRAC10 with GMAC networking + systemd
# WHAT   Boots iDRAC10 AArch64 kernel (NPCM845) under qemu npcm845-evb.
#        Mounts squashfs rootfs from sd.img. Boots with /lib/systemd/systemd.
#        Serial on UNIX socket (or stdio with INTERACTIVE=1).
# HOW    Serial = unix socket; connect: socat - UNIX-CONNECT:/tmp/idrac10-p2.sock
#        Network: GMAC eth0 via fixed-link → QEMU user-mode NAT
#        Ports: 8443→443 (HTTPS/Redfish), 8022→22 (SSH), 8623→623 (IPMI)
# KERNEL boot/Image.boot-p2.patched:
#        Same as p1 but init=/lib/systemd/systemd (offset 17318601)
# DTB    boot/qemu-gmac.dtb:
#        NPCM845 minimal + SDHCI + GMAC (nuvoton,npcm-dwmac + two reg regions
#        + fixed-link + empty mdio subnode to bypass MDIO scan)
set -euo pipefail; cd "$(dirname "$0")"

SOCK=/tmp/idrac10-p2.sock
[ -S "$SOCK" ] && rm -f "$SOCK"

SERIAL_ARG="-serial unix:${SOCK},server,nowait"
[ "${INTERACTIVE:-0}" = "1" ] && SERIAL_ARG="-serial mon:stdio"

exec qemu-system-aarch64 \
  -M npcm845-evb -m 1G \
  -kernel boot/Image.boot-p2.patched \
  -dtb boot/qemu-gmac.dtb \
  -drive "id=rootsd,if=none,file=img/sd.img,format=raw,snapshot=on" \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -display none \
  -nic user,model=npcm-gmac,\
hostfwd=tcp::8443-:443,\
hostfwd=tcp::8022-:22,\
hostfwd=tcp::8623-:623 \
  $SERIAL_ARG \
  "$@"
