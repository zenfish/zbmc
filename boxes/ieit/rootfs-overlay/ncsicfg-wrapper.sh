#!/bin/sh

MAC=52:54:00:12:34:56

ifconfig eth0 down 2>/dev/null || true
ifconfig eth1 down 2>/dev/null || true
ifconfig eth1 hw ether "$MAC" || exit 1
ifconfig eth1 up || exit 1

echo "zbmc: direct QEMU NIC on eth1 ($MAC); vendor NCSI skipped"
