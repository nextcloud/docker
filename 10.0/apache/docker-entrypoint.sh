#!/bin/bash
set -e

if [ ! -e '/var/www/html/version.php' ]; then
    tar cf - --one-file-system -C /usr/src/nextcloud . | tar xf -
    chown -R www-data /var/www/html
fi

exec "$@"
