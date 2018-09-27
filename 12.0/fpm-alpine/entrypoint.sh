#!/bin/sh
set -eu

# version_greater A B returns whether A > B
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

# return true if specified directory is empty
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

run_as() {
    if [ "$(id -u)" = 0 ]; then
        su -p www-data -s /bin/sh -c "$1"
    else
        sh -c "$1"
    fi
}

if expr "$1" : "apache" 1>/dev/null || [ "$1" = "php-fpm" ]; then
    installed_version="0.0.0.0"
    if [ -f /var/www/html/version.php ]; then
        # shellcheck disable=SC2016
        installed_version="$(php -r 'require "/var/www/html/version.php"; echo implode(".", $OC_Version);')"
    fi
    # shellcheck disable=SC2016
    image_version="$(php -r 'require "/usr/src/nextcloud/version.php"; echo implode(".", $OC_Version);')"

    if version_greater "$installed_version" "$image_version"; then
        echo "Can't start Nextcloud because the version of the data ($installed_version) is higher than the docker image version ($image_version) and downgrading is not supported. Are you sure you have pulled the newest image version?"
        exit 1
    fi

    if version_greater "$image_version" "$installed_version"; then
        if [ "$installed_version" != "0.0.0.0" ]; then
            run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_before
        fi
        if [ "$(id -u)" = 0 ]; then
            rsync_options="-rlDog --chown www-data:root"
        else
            rsync_options="-rlD"
        fi
        rsync $rsync_options --delete --exclude /config/ --exclude /data/ --exclude /custom_apps/ --exclude /themes/ /usr/src/nextcloud/ /var/www/html/

        for dir in config data custom_apps themes; do
            if [ ! -d "/var/www/html/$dir" ] || directory_empty "/var/www/html/$dir"; then
                rsync $rsync_options --include "/$dir/" --exclude '/*' /usr/src/nextcloud/ /var/www/html/
            fi
        done

        #install
        if [ "$installed_version" = "0.0.0.0" ]; then
            echo "New nextcloud instance"

            if [ -n "${NEXTCLOUD_ADMIN_USER+x}" ] && [ -n "${NEXTCLOUD_ADMIN_PASSWORD+x}" ]; then
                # shellcheck disable=SC2016
                install_options='-n --admin-user "$NEXTCLOUD_ADMIN_USER" --admin-pass "$NEXTCLOUD_ADMIN_PASSWORD"'
                if [ -n "${NEXTCLOUD_TABLE_PREFIX+x}" ]; then
                    # shellcheck disable=SC2016
                    install_options=$install_options' --database-table-prefix "$NEXTCLOUD_TABLE_PREFIX"'
                else
                    install_options=$install_options' --database-table-prefix ""'
                fi
                if [ -n "${NEXTCLOUD_DATA_DIR+x}" ]; then
                    # shellcheck disable=SC2016
                    install_options=$install_options' --data-dir "$NEXTCLOUD_DATA_DIR"'
                fi

                if [  -n "${SQLITE_DATABASE+x}" ]; then
                    echo "Installing with SQLite database"
                    # shellcheck disable=SC2016
                    install_options=$install_options' --database-name "$SQLITE_DATABASE"'
                    run_as "php /var/www/html/occ maintenance:install $install_options"
                elif [ -n "${MYSQL_DATABASE+x}" ] && [ -n "${MYSQL_USER+x}" ] && [ -n "${MYSQL_PASSWORD+x}" ] && [ -n "${MYSQL_HOST+x}" ]; then
                    echo "Installing with MySQL database"
                    # shellcheck disable=SC2016
                    install_options=$install_options' --database mysql --database-name "$MYSQL_DATABASE" --database-user "$MYSQL_USER" --database-pass "$MYSQL_PASSWORD" --database-host "$MYSQL_HOST"'
                    echo "waiting 30s for the database to setup"
                    sleep 30s
                    echo "starting nexcloud installation"
                    run_as "php /var/www/html/occ maintenance:install $install_options"
                elif [ -n "${POSTGRES_DB+x}" ] && [ -n "${POSTGRES_USER+x}" ] && [ -n "${POSTGRES_PASSWORD+x}" ] && [ -n "${POSTGRES_HOST+x}" ]; then
                    echo "Installing with PostgreSQL database"
                    # shellcheck disable=SC2016
                    install_options=$install_options' --database pgsql --database-name "$POSTGRES_DB" --database-user "$POSTGRES_USER" --database-pass "$POSTGRES_PASSWORD" --database-host "$POSTGRES_HOST"'
                    echo "waiting 10s for the database to setup"
                    sleep 10s
                    echo "starting nexcloud installation"
                    run_as "php /var/www/html/occ maintenance:install $install_options"
                else
                    echo "running web-based installer on first connect!"
                fi
            fi
        #upgrade
        else
            run_as 'php /var/www/html/occ upgrade'

            run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_after
            echo "The following apps have been disabled:"
            diff /tmp/list_before /tmp/list_after | grep '<' | cut -d- -f2 | cut -d: -f1
            rm -f /tmp/list_before /tmp/list_after

        fi
    fi
fi

exec "$@"
