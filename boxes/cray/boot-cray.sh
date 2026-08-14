#!/usr/bin/env bash
# boot-cray.sh — boot the HPE Cray XD670 MegaRAC SP-X BMC (AST2600) to a raw root shell (init=/bin/sh).
#
# WHAT : fastest way in — squashfs rootfs as a RAM disk, drops straight to /bin/sh as PID1. No init,
#        no services, no network. Use for poking the firmware / RE, not for exercising IPMI/Redfish.
# WHY  : proves the firmware runs and gives an unrestricted root shell (the real login shell is the
#        MegaRAC restricted 'defshell').  For the full stack use boot-cray-svc.sh.
# GOTCHAS (learned the hard way):
#   - qemu -kernel cannot unpack a FIT -> we boot the raw kernel.Image extracted by extract.sh.
#   - built-in ram0 caps at 43008 KiB; rootfs is 51108 KiB -> MUST pass ramdisk_size=131072.
#   - console is ttyS4 (AST2600 UART5), matching the firmware's baked-in bootargs.
# RUN  : ./boot-cray.sh              (interactive; Ctrl-A x to quit qemu)
#        echo 'cmds' | ./boot-cray.sh   (feed the shell over stdin; leading delay helps)
# RELATED: extract.sh (makes the artifacts), boot-cray-svc.sh (real init + net), README.html.
set -u
WD="${WD:-/Users/zen/phd/tmp/cray-xd670}"
exec qemu-system-arm -M ast2600-evb -m 1024 -nographic \
  -kernel "$WD/kernel.Image" -dtb "$WD/dtb-a1.dtb" -initrd "$WD/rootfs.sqfs" \
  -append "console=ttyS4,115200n8 root=/dev/ram0 ro rootfstype=squashfs ramdisk_size=131072 ramdisk_blocksize=4096 rootwait init=/bin/sh"
