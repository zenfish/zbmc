#!/usr/bin/env bash
# run-p6emc-test.sh — EMC-as-migratable-NIC experiment (task: option 1).
# Boots the p6 image with the NEW p6emc.dtb (emc0 = fixed-link, NC-SI removed) to test whether the
# on-chip npcm7xx-emc can do link-up + TX WITHOUT the documented NULL kernel crash (which was the
# NC-SI-probe-into-a-non-NCSI-peer path). Keeps usb-net (n1) for ssh/redfish access on 10.0.2.x so we
# never lose the box; peers EMC to a SECOND slirp (n2) on 10.0.3.x for isolated TX testing.
# TEST (after boot, via ssh over usb-net): find the EMC iface, `ip link set <if> up`,
#   `ip addr add 10.0.3.15/24 dev <if>`, `ping 10.0.3.2`. If no kernel crash + ping works -> EMC is a
# viable migratable NIC; switch run-p6.sh to EMC-only and re-checkpoint (restore then keeps network).
# p4.dtb is left pristine (the golden checkpoint depends on it).
set -euo pipefail; cd "$(dirname "$0")"
exec qemu-system-arm -M npcm750-evb -m 1G -display none \
  -kernel boot/uImage.patched -dtb boot/p6emc.dtb -initrd boot/initramfs.p6.xz \
  -drive id=rootsd,if=none,file=img/sd256.img,format=raw,snapshot=on \
  -device sd-card,drive=rootsd,bus=sd-bus \
  -netdev user,id=n1,hostfwd=tcp::2222-:22,hostfwd=udp::6623-:623,hostfwd=tcp::6443-:443 \
  -device usb-net,netdev=n1,bus=usb-bus.0,id=nic0 \
  -netdev user,id=n2,net=10.0.3.0/24,host=10.0.3.2 \
  -net nic,netdev=n2,model=npcm7xx-emc \
  -rtc base=2020-09-20T05:00:00,clock=vm \
  -qmp unix:/tmp/zbmc-idrac9-qmp.sock,server,nowait \
  -serial mon:stdio
