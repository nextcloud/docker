#!/bin/sh
set -eu

while [ 1 ]; do
    (php -f /var/www/html/cron.php &);
    sleep %%CRONTAB_INT%%m;
done
