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
    tar cf - --one-file-system -C /usr/src/nextcloud . | tar xf -
    chown -R www-data /var/www/html
fi

exec "$@"
