#!/bin/sh
set -eu

# Set-up cron entry for previewgenerator (https://apps.nextcloud.com/apps/previewgenerator)
# Note: the user should make sure they install the app first and we could check here but it's non-fatal...
if [ -n "${CRON_PREVIEW+x}" ]; then
    echo "Configuring Preview Generator to run at ${CRON_PREVIEW}:00 (24H system time) if /cron.sh is activated"
    sed -n -e '/preview:pre-generate/!p' -e "\$a\* ${CRON_PREVIEW} \* \* \* /var/www/html/occ preview:pre-generate" \
            /var/spool/cron/crontabs/www-data > /var/spool/cron/crontabs/www-data.tmp && \
            mv /var/spool/cron/crontabs/www-data.tmp /var/spool/cron/crontabs/www-data
fi

exec busybox crond -f -l 0 -L /dev/stdout
