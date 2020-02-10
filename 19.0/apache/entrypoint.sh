#!/bin/sh
set -eu

run_as() {
    if [ "$(id -u)" = 0 ]; then
        su -p www-data -s /bin/sh -c "$1"
    else
        sh -c "$1"
    fi
}

if expr "$1" : "apache" 1>/dev/null || [ "$1" = "php-fpm" ] || [ "${NEXTCLOUD_UPDATE:-0}" -eq 1 ]; then
    if [ -n "${REDIS_HOST+x}" ]; then

        echo "Configuring Redis as session handler"
        {
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
        } > /usr/local/etc/php/conf.d/redis-session.ini
    fi

    #upgrade
    if php occ status | grep installed | grep true; then
        run_as 'php /var/www/html/occ upgrade'
    #install
    else
        echo "New nextcloud instance"

        if [ -n "${NEXTCLOUD_ADMIN_USER+x}" ] && [ -n "${NEXTCLOUD_ADMIN_PASSWORD+x}" ]; then
            # shellcheck disable=SC2016
            install_options='-n --admin-user "$NEXTCLOUD_ADMIN_USER" --admin-pass "$NEXTCLOUD_ADMIN_PASSWORD"'
            if [ -n "${NEXTCLOUD_TABLE_PREFIX+x}" ]; then
                # shellcheck disable=SC2016
                install_options=$install_options' --database-table-prefix "$NEXTCLOUD_TABLE_PREFIX"'
            fi
            if [ -n "${NEXTCLOUD_DATA_DIR+x}" ]; then
                # shellcheck disable=SC2016
                install_options=$install_options' --data-dir "$NEXTCLOUD_DATA_DIR"'
            fi

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
    fi
fi

exec "$@"
