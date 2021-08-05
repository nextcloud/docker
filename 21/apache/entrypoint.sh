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

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    local varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
    local fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")
    if [ -n "${varValue}" ] && [ -n "${fileVarValue}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    if [ -n "${varValue}" ]; then
        export "$var"="${varValue}"
    elif [ -n "${fileVarValue}" ]; then
        export "$var"="$(cat "${fileVarValue}")"
    elif [ -n "${def}" ]; then
        export "$var"="$def"
    fi
    unset "$fileVar"
}

if expr "$1" : "apache" 1>/dev/null; then
    if [ -n "${APACHE_DISABLE_REWRITE_IP+x}" ]; then
        a2disconf remoteip
    fi
fi

if expr "$1" : "apache" 1>/dev/null || [ "$1" = "php-fpm" ] || [ "${NEXTCLOUD_UPDATE:-0}" -eq 1 ]; then
    if [ -n "${REDIS_HOST+x}" ]; then

        echo "Configuring Redis as session handler"
        {
            file_env REDIS_HOST_PASSWORD
            echo 'session.save_handler = redis'
            # check if redis host is an unix socket path
            if [ "$(echo "$REDIS_HOST" | cut -c1-1)" = "/" ]; then
              if [ -n "${REDIS_HOST_PASSWORD+x}" ]; then
                echo "session.save_path = \"unix://${REDIS_HOST}?auth=${REDIS_HOST_PASSWORD}\""
              else
                echo "session.save_path = \"unix://${REDIS_HOST}\""
              fi
            # check if redis password has been set
            elif [ -n "${REDIS_HOST_PASSWORD+x}" ]; then
                echo "session.save_path = \"tcp://${REDIS_HOST}:${REDIS_HOST_PORT:=6379}?auth=${REDIS_HOST_PASSWORD}\""
            else
                echo "session.save_path = \"tcp://${REDIS_HOST}:${REDIS_HOST_PORT:=6379}\""
            fi
            echo "redis.session.locking_enabled = 1"
            echo "redis.session.lock_retries = -1"
            # redis.session.lock_wait_time is specified in microseconds.
            # Wait 10ms before retrying the lock rather than the default 2ms.
            echo "redis.session.lock_wait_time = 10000"
        } > /usr/local/etc/php/conf.d/redis-session.ini
    fi

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
        echo "Initializing nextcloud $image_version ..."
        if [ "$installed_version" != "0.0.0.0" ]; then
            echo "Upgrading nextcloud from $installed_version ..."
            run_as 'php /var/www/html/occ app:list' | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_before
        fi
        if [ "$(id -u)" = 0 ]; then
            rsync_options="-rlDog --chown www-data:root"
        else
            rsync_options="-rlD"
        fi
        rsync $rsync_options --delete --exclude-from=/upgrade.exclude /usr/src/nextcloud/ /var/www/html/

        for dir in config data custom_apps themes; do
            if [ ! -d "/var/www/html/$dir" ] || directory_empty "/var/www/html/$dir"; then
                rsync $rsync_options --include "/$dir/" --exclude '/*' /usr/src/nextcloud/ /var/www/html/
            fi
        done
        rsync $rsync_options --include '/version.php' --exclude '/*' /usr/src/nextcloud/ /var/www/html/
        echo "Initializing finished"

        #install
        if [ "$installed_version" = "0.0.0.0" ]; then
            echo "New nextcloud instance"

            file_env NEXTCLOUD_ADMIN_PASSWORD
            file_env NEXTCLOUD_ADMIN_USER

            if [ -n "${NEXTCLOUD_ADMIN_USER+x}" ] && [ -n "${NEXTCLOUD_ADMIN_PASSWORD+x}" ]; then
                # shellcheck disable=SC2016
                install_options='-n --admin-user "$NEXTCLOUD_ADMIN_USER" --admin-pass "$NEXTCLOUD_ADMIN_PASSWORD"'
                if [ -n "${NEXTCLOUD_DATA_DIR+x}" ]; then
                    # shellcheck disable=SC2016
                    install_options=$install_options' --data-dir "$NEXTCLOUD_DATA_DIR"'
                fi

                file_env MYSQL_DATABASE
                file_env MYSQL_PASSWORD
                file_env MYSQL_USER
                file_env POSTGRES_DB
                file_env POSTGRES_PASSWORD
                file_env POSTGRES_USER

                install=false
                if [ -n "${SQLITE_DATABASE+x}" ]; then
                    echo "Installing with SQLite database"
                    # shellcheck disable=SC2016
                    install_options=$install_options' --database-name "$SQLITE_DATABASE"'
                    install=true
                elif [ -n "${MYSQL_DATABASE+x}" ] && [ -n "${MYSQL_USER+x}" ] && [ -n "${MYSQL_PASSWORD+x}" ] && [ -n "${MYSQL_HOST+x}" ]; then
                    echo "Installing with MySQL database"
                    # shellcheck disable=SC2016
                    install_options=$install_options' --database mysql --database-name "$MYSQL_DATABASE" --database-user "$MYSQL_USER" --database-pass "$MYSQL_PASSWORD" --database-host "$MYSQL_HOST"'
                    install=true
                elif [ -n "${POSTGRES_DB+x}" ] && [ -n "${POSTGRES_USER+x}" ] && [ -n "${POSTGRES_PASSWORD+x}" ] && [ -n "${POSTGRES_HOST+x}" ]; then
                    echo "Installing with PostgreSQL database"
                    # shellcheck disable=SC2016
                    install_options=$install_options' --database pgsql --database-name "$POSTGRES_DB" --database-user "$POSTGRES_USER" --database-pass "$POSTGRES_PASSWORD" --database-host "$POSTGRES_HOST"'
                    install=true
                fi

                if [ "$install" = true ]; then
                    echo "starting nextcloud installation"
                    max_retries=10
                    try=0
                    until run_as "php /var/www/html/occ maintenance:install $install_options" || [ "$try" -gt "$max_retries" ]
                    do
                        echo "retrying install..."
                        try=$((try+1))
                        sleep 10s
                    done
                    if [ "$try" -gt "$max_retries" ]; then
                        echo "installing of nextcloud failed!"
                        exit 1
                    fi
                    if [ -n "${NEXTCLOUD_TRUSTED_DOMAINS+x}" ]; then
                        echo "setting trusted domains…"
                        NC_TRUSTED_DOMAIN_IDX=1
                        for DOMAIN in $NEXTCLOUD_TRUSTED_DOMAINS ; do
                            DOMAIN=$(echo "$DOMAIN" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                            run_as "php /var/www/html/occ config:system:set trusted_domains $NC_TRUSTED_DOMAIN_IDX --value=$DOMAIN"
                            NC_TRUSTED_DOMAIN_IDX=$(($NC_TRUSTED_DOMAIN_IDX+1))
                        done
                    fi
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
