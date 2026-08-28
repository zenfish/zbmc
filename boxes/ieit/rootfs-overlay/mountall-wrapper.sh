#!/bin/sh

vendor_status=0
/etc/init.d/mountall.vendor.sh "$@" || vendor_status=$?

case "$1" in
    start|"")
        /etc/init.d/zbmc-runtime.sh || exit $?
        ;;
esac

exit "$vendor_status"
