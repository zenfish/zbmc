#!/bin/sh

case "${1:-}" in
    start|restart)
        echo "zbmc: CommerDiagnose disabled (board EEPROM and host complex are not modeled)"
        ;;
    stop|reload|force-reload)
        ;;
    *)
        echo "Usage: /etc/init.d/commerDiagnoseServer {start|stop|reload|restart|force-reload}" >&2
        exit 1
        ;;
esac

exit 0
