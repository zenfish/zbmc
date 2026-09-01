#!/bin/sh

case "${1:-}" in
  start|restart)
    echo "zbmc: ${0##*/} disabled (host power/PCIe/ME hardware is not modeled)"
    ;;
esac

exit 0
