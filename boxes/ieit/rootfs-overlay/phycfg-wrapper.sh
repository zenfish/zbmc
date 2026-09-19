#!/bin/sh

MAC=52:54:00:fa:00:41

ifconfig eth1 down 2>/dev/null || true
ifconfig eth1 hw ether "$MAC" || exit 1
ifconfig eth1 up || exit 1

echo "zbmc: direct QEMU PHY configured on eth1"
