#!/bin/sh
set -eu

[ -e /var/www/html/occ ] || { echo "Unable to run \`occ\`: No such file or directory" >&2 ; exit 1 ; }
[ -f /var/www/html/occ ] || { echo "Unable to run \`occ\`: Not a file" >&2 ; exit 1 ; }

RUN_AS="$(stat -c %U /var/www/html/occ)"
[ -n "$RUN_AS" ] && [ "$RUN_AS" != "UNKNOWN" ] || { echo "Unable to run \`occ\`: Failed to determine www-data user" >&2 ; exit 1 ; }

if [ "$(id -u)" = 0 ]; then
    exec su -p "$RUN_AS" -s /bin/sh -c 'exec php -f /var/www/html/occ -- "$@"' -- '/bin/sh' "$@"
else
    exec php -f /var/www/html/occ -- "$@"
fi
