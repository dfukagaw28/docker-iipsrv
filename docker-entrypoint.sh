#!/bin/sh
# lighttpd and iipsrv run as www-data and write their logs to
# /run/log/stderr.fifo (via the symlinks in /var/log). This FIFO is owned by
# www-data and relayed to the container's stderr, because the container's own
# stderr may not be writable by www-data (e.g. Docker without a TTY, where it
# is a pipe owned by root with mode 600).
set -eu

FIFO=/run/log/stderr.fifo

if [ "$(id -u)" = 0 ]; then
    mkdir -p "${FIFO%/*}"
    rm -f "$FIFO"
    mkfifo -m 600 "$FIFO"
    chown www-data:www-data "$FIFO"
    # Open read-write so that cat never sees EOF when writers come and go.
    cat <> "$FIFO" >&2 &
fi

# Number of iipsrv processes, read by lighttpd.conf
case "${IIPSRV_PROCS:-1}" in
    ''|*[!0-9]*|0|0*) echo "IIPSRV_PROCS must be a positive integer, got '${IIPSRV_PROCS:-}'" >&2; exit 1 ;;
esac

exec "$@"
