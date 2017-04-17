#!/bin/bash
set -e

# version_greater A B returns whether A > B
function version_greater() {
	[[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" ]];
}

installed_version="0.0.0~unknown"
if [ -f /var/www/html/version.php ]; then
    installed_version=$(php -r 'require "/var/www/html/version.php"; echo "$OC_VersionString";')
fi
image_version=$(php -r 'require "/usr/src/nextcloud/version.php"; echo "$OC_VersionString";')

if version_greater "$installed_version" "$image_version"; then
    echo "Downgrade not supported"
    exit 1
fi

if version_greater "$image_version" "$installed_version"; then
    if [ "$installed_version" != "0.0.0~unknown" ]; then
        su - www-data -s /bin/bash -c 'php /var/www/html/occ app:list' > /tmp/list_before
    fi

    rsync -a --delete --exclude /config/ --exclude /data/ --exclude /apps/ /usr/src/nextcloud/ /var/www/html/

    if [ ! -d /var/www/html/config ]; then
        cp -arT /usr/src/nextcloud/config /var/www/html/config
    fi

    mkdir -p /var/www/html/apps
    for app in `find /usr/src/nextcloud/apps -maxdepth 1 -mindepth 1 -type d | cut -d / -f 6`; do
        rm -rf /var/www/html/apps/$app
        cp -arT /usr/src/nextcloud/apps/$app /var/www/html/apps/$app
    done

    chown -R www-data /var/www/html

    if [ "$installed_version" != "0.0.0~unknown" ]; then
        su - www-data -s /bin/bash -c 'php /var/www/html/occ upgrade --no-app-disable'

        su - www-data -s /bin/bash -c 'php /var/www/html/occ app:list' > /tmp/list_after
        echo "The following apps have beed disabled:"
        diff <(sed -n "/Enabled:/,/Disabled:/p" /tmp/list_before) <(sed -n "/Enabled:/,/Disabled:/p" /tmp/list_after) | grep '<' | cut -d- -f2 | cut -d: -f1
        rm -f /tmp/list_before /tmp/list_after
    fi
fi

exec "$@"
