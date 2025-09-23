#!/bin/sh
set -eu

###############################################################################
# Entrypoint script for Nextcloud Docker container
###############################################################################

# Handles container-specific operations such as initialization, automatic configuration,
# user/group ID management, and setup checks. Also runs Nextcloud Server’s built-in
# installation and upgrade routines in a way that fits the container environment.
#
# Supports environment-based configuration injection at install time for all key
# parameters (see README for details). After installation, allows reconfiguration
# of select parameters via environment variables - except NEXTCLOUD_TRUSTED_DOMAINS
# and those set by the Nextcloud installer.
#
# REMINDER: This script must work with non-interactive, POSIX-compliant shells used in our
# images. Do not use Bash-specific syntax ("bashisms"): /bin/sh is always either 'ash'
# (BusyBox) or 'dash' (Debian), not Bash. Stick to standard POSIX shell features.
# Resources for writing portable shell scripts:
#   - checkbashisms (Alpine: checkbashisms; Debian: devscripts)
#   - https://mywiki.wooledge.org/Bashism
#   - https://www.shellcheck.net/
# Same also applies to any commands called too (e.g., GNU find versus Busybox find).

###############################################################################
# Utility Functions
###############################################################################

# Command for running `occ`
OCC="php /var/www/html/occ"

# version_greater
# Compare two version strings (A and B).
# Arguments:
#   $1: Version string A
#   $2: Version string B
# Returns: 0 (true) if version A is greater than B; 1 (false) otherwise.
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

# directory_empty
# Check if a directory is empty.
# Arguments:
#   $1: Directory path.
# Returns: 0 (true) if directory is empty; 1 (false) otherwise.
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

# run_as
# Run a command as the specified user if running as root, otherwise as current user.
# Arguments:
#   $1: Command string to execute.
# Globals:
#   user - Username to switch to (when running as root).
# Returns: the exit code of the executed command.
# TODO:
#   Consider printing error message then returning (or exiting the script) if a command fails.
#   If some callers want to handle errors, hide behind optional flag ("--exit-on-error").
run_as() {
    if [ "$(id -u)" = 0 ]; then
        su -p "$user" -s /bin/sh -c "$1"
    else
        sh -c "$1"
    fi
}

# run_path
# Execute all executable .sh files in the specified hook folder, in alphanumeric order.
# Arguments:
#   $1: Name of the hook folder inside /docker-entrypoint-hooks.d/
# Returns: 0 on success; exits the script on any hook failure.
run_path() {
    hook_folder_path="/docker-entrypoint-hooks.d/$1"
    return_code=0
    found=0

    echo "=> Searching for hook scripts (*.sh) to run in \"${hook_folder_path}\""

    if ! [ -d "${hook_folder_path}" ] || directory_empty "${hook_folder_path}"; then
        echo "==> Skipped: the \"$1\" folder is empty (or does not exist)"
        return 0
    fi

    find "${hook_folder_path}" -maxdepth 1 -iname '*.sh' '(' -type f -o -type l ')' -print | sort | (
        while read -r script_file_path; do
            if ! [ -x "${script_file_path}" ]; then
                echo "==> The script \"${script_file_path}\" was skipped: lacks exec flag"
                found=$((found-1))
                continue
            fi

            echo "==> Running script (cwd: $(pwd)): \"${script_file_path}\""
            found=$((found+1))
            run_as "${script_file_path}" || return_code="$?"

            if [ "${return_code}" -ne "0" ]; then
                echo "==> Failed executing \"${script_file_path}\". Exit code: ${return_code}"
                exit 1
            fi

            echo "==> Finished executing: \"${script_file_path}\""
        done

        if [ "$found" -lt "1" ]; then
            echo "==> Skipped: the \"$1\" folder contains no valid scripts"
        else
            echo "=> Completed executing scripts in \"$1\""
        fi
    )
}

# file_env
# Load an environment variable from a file if available (supporting Docker secrets).
# Arguments:
#   $1: Name of the environment variable.
#   $2: (Optional) Default value if not set.
# Returns: Sets the environment variable named by $1.
file_env() {
    var="$1"
    fileVar="${var}_FILE"
    def="${2:-}"
    varValue=$(env | grep -E "^${var}=" | sed -E -e "s/^${var}=//")
    fileVarValue=$(env | grep -E "^${fileVar}=" | sed -E -e "s/^${fileVar}=//")
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

###############################################################################
# rsync_wrapper
# Helper to invoke rsync with the appropriate options depending on user/group.
# Arguments:
#   $@ - Additional rsync arguments and paths.
# Globals:
#   user - Username to use for chown (when running as root).
# Returns: the exit code of the rsync command.
# 
# Handles:
#   - SC2086 and word-splitting safely
#   - DRY invocation of rsync for all sync operations
###############################################################################
rsync_wrapper() {
    if [ "$(id -u)" = 0 ]; then
        set -- -rlDog --chown "$user:$group" "$@"
    else
        set -- -rlD "$@"
    fi
    rsync "$@"
}

###############################################################################
# Main Entrypoint Logic
###############################################################################

# Disable the Apache remoteip configuration if requested via environment variable.
# TODO: This probably be moved inside the main initialization/upgrade block below.
if expr "$1" : "apache" 1>/dev/null; then
    if [ -n "${APACHE_DISABLE_REWRITE_IP+x}" ]; then
        a2disconf remoteip
    fi
fi

# Only run this block if entrypoint command is Apache|PHP-FPM, or if explicitly requested.
# TODO: This huge block should probably be broken into several discrete functions for maintainability.
if expr "$1" : "apache" 1>/dev/null || [ "$1" = "php-fpm" ] || [ "${NEXTCLOUD_UPDATE:-0}" -eq 1 ]; then

    uid="$(id -u)"
    gid="$(id -g)"

    # Determine effective user and group for Nextcloud operations.
    if [ "$uid" = '0' ]; then
        case "$1" in
            apache2*)
                user="${APACHE_RUN_USER:-www-data}"
                group="${APACHE_RUN_GROUP:-www-data}"
                # Strip off any '#' symbol ('#1000' is valid syntax for Apache)
                user="${user#'#'}"
                group="${group#'#'}"
                ;;
            *) # php-fpm
                user='www-data'
                group='www-data'
                ;;
        esac
    else
        user="$uid"
        group="$gid"
    fi

    # If REDIS_HOST is set, configure PHP sessions to use Redis.
    if [ -n "${REDIS_HOST+x}" ]; then
        echo "Configuring Redis as session handler"

        file_env REDIS_HOST_PASSWORD

        # Determine session.save_path depending on socket or TCP and credentials.
        redis_save_path=""
        first_char=$(printf '%s' "$REDIS_HOST" | cut -c1-1)
        if [ "$first_char" = "/" ]; then
            # Unix socket
            if [ -n "${REDIS_HOST_PASSWORD+x}" ]; then
                if [ -n "${REDIS_HOST_USER+x}" ]; then
                    redis_save_path="unix://${REDIS_HOST}?auth[]=${REDIS_HOST_USER}&auth[]=${REDIS_HOST_PASSWORD}"
                else
                    redis_save_path="unix://${REDIS_HOST}?auth=${REDIS_HOST_PASSWORD}"
                fi
            else
                redis_save_path="unix://${REDIS_HOST}"
            fi
        elif [ -n "${REDIS_HOST_PASSWORD+x}" ]; then
            # TCP with password
            if [ -n "${REDIS_HOST_USER+x}" ]; then
                redis_save_path="tcp://${REDIS_HOST}:${REDIS_HOST_PORT:=6379}?auth[]=${REDIS_HOST_USER}&auth[]=${REDIS_HOST_PASSWORD}"
            else
                redis_save_path="tcp://${REDIS_HOST}:${REDIS_HOST_PORT:=6379}?auth=${REDIS_HOST_PASSWORD}"
            fi
        else
            # TCP without password
            redis_save_path="tcp://${REDIS_HOST}:${REDIS_HOST_PORT:=6379}"
        fi

        # Write the configuration file using a heredoc.
        cat > /usr/local/etc/php/conf.d/redis-session.ini <<EOF
session.save_handler = redis
session.save_path = "${redis_save_path}"
redis.session.locking_enabled = 1
redis.session.lock_retries = -1
# redis.session.lock_wait_time is specified in microseconds.
# Wait 10ms before retrying the lock rather than the default 2ms.
redis.session.lock_wait_time = 10000
EOF
    fi

    # Use file locking to ensure only one initialization or upgrade runs at a time.
    (
        if ! flock -n 9; then
            echo "Another process is initializing Nextcloud. Waiting..."
            flock 9
        fi

        installed_version="0.0.0.0"
        if [ -f /var/www/html/version.php ]; then
            # TODO: The error handling should be improved here in case of syntax/etc errors
            # shellcheck disable=SC2016
            installed_version="$(php -r 'require "/var/www/html/version.php"; echo implode(".", $OC_Version);')"
        fi

        # TODO: The error handling should be improved here in case of syntax/etc errors
        # shellcheck disable=SC2016
        image_version="$(php -r 'require "/usr/src/nextcloud/version.php"; echo implode(".", $OC_Version);')"

        if version_greater "$installed_version" "$image_version"; then
            echo "Can't start Nextcloud: data version ($installed_version) is higher than"
            echo "docker image version ($image_version); downgrading is not supported."
            echo "Are you sure you have pulled a newer image version?"
            exit 1
        fi

        # Image version needs to be > installed version to proceed farther.
        # NOTE: Also true if there is no installed version.
        if version_greater "$image_version" "$installed_version"; then
            echo "Initializing nextcloud $image_version ..."

            # Check for an already installed version that isn't in allowable upgrade jump range.
            if [ "$installed_version" != "0.0.0.0" ]; then
                if [ "${image_version%%.*}" -gt "$((${installed_version%%.*} + 1))" ]; then
                    echo "Can't start Nextcloud: upgrading from $installed_version to"
                    echo "$image_version is not supported."
                    echo "You can upgrade only one major version at a time."
                    echo "E.g., to upgrade from 14 to 16, first upgrade 14 to 15, then 15 to 16."
                    exit 1
                fi
                # Installed version has been deemed within allow upgrade jump range...
                echo "Upgrading nextcloud from $installed_version ..."
                run_as "$OCC app:list" | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_before
            fi

            # Deploy image code onto the persistent storage volume.
            ##########################################################################################
            # Why we copy Nextcloud code from the image to persistent storage
            #
            # Nextcloud's application directory needs to be on persistent storage, not just inside
            # the container's writable/read-only layers. This ensures:
            #   - All code and changes survive container restarts and replacements.
            #   - Clustering (using multiple containers with shared data) functions as expected.
            #   - Nextcloud can safely modify, add, or remove files (mainly under config/, data/, apps/, 
            #     custom_apps/) during normal operation.
            #   - Upgrades, apps, and troubleshooting work reliably.
            #
            # The container’s writable layer is temporary and unique to each container. Changes made there
            # are lost if the container is removed and are not shared between containers.
            #
            # This approach follows Nextcloud's official installation conventions and is necessary for
            # robust container deployments.
            #
            # Note:
            #   - Actual file changes are typically limited to config/, data/, apps/, and custom_apps/ 
            #     in a standard setup (so there may be some room for improvement here).
            #
            # TODO:
            #   - Consider ways to further streamline this process upstream.
            #   - Investigate separating truly read-only folders from writable ones.
            ##########################################################################################

            # Replace installed code with newer image code except for exclusions.
            #
            # Risks & Considerations:
            #   - Deleting files not listed in the exclusions file could remove legitimate Nextcloud data
            #     if users overlook documentation or misconfigure persistent storage.
            #   - Using rsync (cp would be similar) are slow on NFS and other network filesystems,
            #     sometimes merely annoyingly; sometimes unacceptably.
            #
            # Alternative Approaches:
            #   - Warn if we detect unexpected files that would be deleted, but avoid a hard error to
            #     allow legitimate Nextcloud files/folders.
            #   - A dry-run mode with a hard error would prevent mistakes, but also block valid upgrades.
            #   - Batching files with tar on both ends of a pipe might help with performance.
            #
            # TODO:
            #   - Print a warning if non-excluded files are detected for deletion.
            #   - Investigate a middle ground between safety (preventing accidental deletion)
            #     and usability (supporting easy upgrades).
            #   - Consider batching file transfers for better performance on network filesystems.
            #
            # Notes:
            #   - The current rsync approach works for local filesystems but may be slow or appear
            #     to hang on networked storage.

            rsync_wrapper \
                --delete \
                --exclude-from=/upgrade.exclude \
                /usr/src/nextcloud/ \
                /var/www/html/

            # Copy newer image code for the following directories ONLY if they do not exist or are empty:
            #   - config/
            #   - data/
            #   - custom_apps/
            #   - themes/
            #
            # TODO:
            #   - Consider updating only 'themes/' here, and move handling of 'config/', 'data/', and
            #     'custom_apps/' into the install block. These directories should not be modified during a
            #     regular update/upgrade.
            #   - Review whether this change would cause any unexpected behavior or introduce breaking
            #     changes.
            
            for dir in config data custom_apps themes; do
                if [ ! -d "/var/www/html/$dir" ] || directory_empty "/var/www/html/$dir"; then
                    rsync_wrapper \
                        --include "/$dir/" \
                        --exclude '/*' \
                        /usr/src/nextcloud/ \
                        /var/www/html/
                fi
            done

            # Replace installed code's version.php with newer image code version
            rsync_wrapper \
                --include '/version.php' \
                --exclude '/*' \
                /usr/src/nextcloud/ \
                /var/www/html/

            # Install block for fresh instances.
            # TODO: Consider moving install block to a dedicated function
            if [ "$installed_version" = "0.0.0.0" ]; then
                echo "New nextcloud instance"

                # Handle initial admin credentials (if provided)
                file_env NEXTCLOUD_ADMIN_PASSWORD
                file_env NEXTCLOUD_ADMIN_USER

                install=false
                if [ -n "${NEXTCLOUD_ADMIN_USER+x}" ] \
                    && [ -n "${NEXTCLOUD_ADMIN_PASSWORD+x}" ]; then
                    install_options="-n \
                        --admin-user \"$NEXTCLOUD_ADMIN_USER\" \
                        --admin-pass \"$NEXTCLOUD_ADMIN_PASSWORD\""

                    if [ -n "${NEXTCLOUD_DATA_DIR+x}" ]; then
                        install_options="$install_options \
                            --data-dir \"$NEXTCLOUD_DATA_DIR\""
                    fi

                    # Handle database configuration (if specified)
                    file_env MYSQL_DATABASE
                    file_env MYSQL_PASSWORD
                    file_env MYSQL_USER
                    file_env POSTGRES_DB
                    file_env POSTGRES_PASSWORD
                    file_env POSTGRES_USER

                    if [ -n "${SQLITE_DATABASE+x}" ]; then
                        echo "Installing with SQLite database"
                        install_options="$install_options \
                            --database-name \"$SQLITE_DATABASE\""
                        install=true
                    elif [ -n "${MYSQL_DATABASE+x}" ] \
                        && [ -n "${MYSQL_USER+x}" ] \
                        && [ -n "${MYSQL_PASSWORD+x}" ] \
                        && [ -n "${MYSQL_HOST+x}" ]; then
                        echo "Installing with MySQL database"
                        install_options="$install_options \
                            --database mysql \
                            --database-name \"$MYSQL_DATABASE\" \
                            --database-user \"$MYSQL_USER\" \
                            --database-pass \"$MYSQL_PASSWORD\" \
                            --database-host \"$MYSQL_HOST\""
                        install=true
                    elif [ -n "${POSTGRES_DB+x}" ] \
                        && [ -n "${POSTGRES_USER+x}" ] \
                        && [ -n "${POSTGRES_PASSWORD+x}" ] \
                        && [ -n "${POSTGRES_HOST+x}" ]; then
                        echo "Installing with PostgreSQL database"
                        install_options="$install_options \
                            --database pgsql \
                            --database-name \"$POSTGRES_DB\" \
                            --database-user \"$POSTGRES_USER\" \
                            --database-pass \"$POSTGRES_PASSWORD\" \
                            --database-host \"$POSTGRES_HOST\""
                        install=true
                    fi

                    # Run Nextcloud installer if we were provided enough auto-config values.
                    # (if not, we don't trigger the actual Nextcloud installer; the config values
                    # will need to be provided via the Nextcloud Installer's Web UI / wizard).
                    if [ "$install" = true ]; then
                        # Trigger pre-installation hook scripts (if any)
                        run_path pre-installation

                        echo "Starting nextcloud installation"
                        max_retries=10
                        try=0
                        until [ "$try" -gt "$max_retries" ] || run_as \
                            "$OCC maintenance:install $install_options"
                        do
                            echo "Retrying install..."
                            try=$((try+1))
                            sleep 10s
                        done
                        if [ "$try" -gt "$max_retries" ]; then
                            echo "Installation of nextcloud failed!"
                            exit 1
                        fi

                        # Configure trusted domains if provided.
                        # TODO: This could probably be moved elsewhere to permit reconfiguration within existing installs.
                        if [ -n "${NEXTCLOUD_TRUSTED_DOMAINS+x}" ]; then
                            echo "Setting trusted_domains…"
                            set -f # turn off glob
                            NC_TRUSTED_DOMAIN_IDX=1
                            for DOMAIN in ${NEXTCLOUD_TRUSTED_DOMAINS}; do
                                DOMAIN=$(echo "${DOMAIN}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
                                run_as \
                                    "$OCC config:system:set trusted_domains $NC_TRUSTED_DOMAIN_IDX --value=\"${DOMAIN}\""
                                NC_TRUSTED_DOMAIN_IDX=$((NC_TRUSTED_DOMAIN_IDX+1))
                            done
                            set +f # turn glob back on
                        fi

                        # Trigger post-installation hook scripts (if any)
                        run_path post-installation
                    fi
                fi

                # Not enough parameters specified to do a fully automated installation.
                if [ "$install" = false ]; then 
                    echo "Next step: Access your instance to finish the web-based installation!"
                    echo "Hint: Set NEXTCLOUD_ADMIN_USER, NEXTCLOUD_ADMIN_PASSWORD, and DB vars"
                    echo "before first launch to fully automate initial installation."
                fi

            # Upgrade path for existing instances.
            # TODO: Consider moving upgrade block to a dedicated function
            else
                # Trigger pre-upgrade hook scripts (if any)
                run_path pre-upgrade

                run_as "$OCC upgrade"

                run_as "$OCC app:list" | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_after
                echo "The following apps have been disabled:"
                diff /tmp/list_before /tmp/list_after \
                    | grep '<' | cut -d- -f2 | cut -d: -f1
                rm -f /tmp/list_before /tmp/list_after

                # Trigger post-upgrade hook scripts (if any)
                run_path post-upgrade
            fi

            echo "Initializing finished"
        fi

        # Update htaccess after init if requested
        if [ -n "${NEXTCLOUD_INIT_HTACCESS+x}" ] \
            && [ "$installed_version" != "0.0.0.0" ]; then
            run_as "$OCC maintenance:update:htaccess"
        fi
    ) 9> /var/www/html/nextcloud-init-sync.lock

    # Warn the user if any config files in persistent storage differ from the image defaults.
    for cfgPath in /usr/src/nextcloud/config/*.php; do
        cfgFile=$(basename "$cfgPath")

        if [ "$cfgFile" != "config.sample.php" ] \
            && [ "$cfgFile" != "autoconfig.php" ]; then
            if ! cmp -s "/usr/src/nextcloud/config/$cfgFile" "/var/www/html/config/$cfgFile"; then
                echo "Warning: /var/www/html/config/$cfgFile differs from the image default at"
                echo "  /usr/src/nextcloud/config/$cfgFile"
            fi
        fi
    done

    # Trigger before-starting hook scripts (if any)
    run_path before-starting
fi

###############################################################################
# Handoff to Main Container Process
###############################################################################

# Hand off to the main container process (e.g., Apache, php-fpm, etc.)
exec "$@"
