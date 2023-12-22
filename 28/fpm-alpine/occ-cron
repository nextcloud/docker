#!/bin/sh
set -eu

if [ "$(occ status 2> /dev/null | sed -ne 's/^  - installed: \(.*\)$/\1/p')" != "true" ]; then
    echo "Nextcloud is not installed - cronjobs are not available" >&2
    exit 1
fi

[ -e /var/www/html/cron.php ] || { echo "Unable to run \`occ-cron\`: No such file or directory" >&2 ; exit 1 ; }
[ -f /var/www/html/cron.php ] || { echo "Unable to run \`occ-cron\`: Not a file" >&2 ; exit 1 ; }

RUN_AS="$(stat -c %U /var/www/html/cron.php)"
[ -n "$RUN_AS" ] && [ "$RUN_AS" != "UNKNOWN" ] || { echo "Unable to run \`occ-cron\`: Failed to determine www-data user" >&2 ; exit 1 ; }

if [ "$(id -u)" = 0 ]; then
    exec su -p "$RUN_AS" -s /bin/sh -c 'exec php -f /var/www/html/cron.php' -- '/bin/sh'
else
    exec php -f /var/www/html/cron.php
fi
