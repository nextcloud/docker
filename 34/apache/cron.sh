#!/bin/sh
set -eu

crontabs=/var/spool/cron/crontabs

if [ -n "${NEXTCLOUD_CRON_SCHEDULE:-}" ]; then
	crontabs="${TMPDIR:-/tmp}/nextcloud-crontabs"
	mkdir -p "$crontabs"
	echo "$NEXTCLOUD_CRON_SCHEDULE php -f /var/www/html/cron.php" > "$crontabs/www-data"
fi

exec busybox crond -f -L /dev/stdout -c "$crontabs"
