#!/bin/sh
set -eu

###############################################################################
# Entrypoint script for Nextcloud Docker container
###############################################################################
#
# Handles container-specific operations such as initialization, automatic configuration,
# user/group ID management, and setup checks. Also runs Nextcloud Server’s built-in
# installation and upgrade routines in a way that fits the container environment.
#
# Supports environment-based configuration injection at install time for all key
# parameters (see README for details). After installation, allows reconfiguration
# of select parameters via environment variables - except NEXTCLOUD_TRUSTED_DOMAINS
# and those set by the Nextcloud installer.
#
# See README.md for more details and usage examples:
#    https://github.com/nextcloud/docker?tab=readme-ov-file
#
# REMINDER (to modifiers/contributors): This script must work with non-interactive,
# POSIX-compliant shells used in our images. Do not use Bash-specific syntax ("bashisms"):
# /bin/sh is always either 'ash' (BusyBox) or 'dash' (Debian), not Bash. Stick to standard
# POSIX shell features. Resources for writing portable shell scripts:
#   - checkbashisms (Alpine: checkbashisms; Debian: devscripts)
#   - https://mywiki.wooledge.org/Bashism
#   - https://www.shellcheck.net/
# Same also applies to any commands called too (e.g., GNU find versus Busybox find).

###############################################################################
# Supported Environment Variables
#
# NEXTCLOUD_ADMIN_USER         - Username for initial admin account (install only)
# NEXTCLOUD_ADMIN_PASSWORD     - Password for initial admin account (install only)
# NEXTCLOUD_TRUSTED_DOMAINS    - Space-separated list of trusted domains
# NEXTCLOUD_DATA_DIR           - Path to Nextcloud data directory
# MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD, MYSQL_HOST
# POSTGRES_DB, POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_HOST
# SQLITE_DATABASE
# REDIS_HOST, REDIS_HOST_USER, REDIS_HOST_PASSWORD, REDIS_HOST_PORT
# APACHE_RUN_USER, APACHE_RUN_GROUP
# APACHE_DISABLE_REWRITE_IP    - If present, disables Apache remoteip module
# NEXTCLOUD_UPDATE             - If set (e.g., to 1), forces update logic
# NEXTCLOUD_INIT_HTACCESS      - If set, runs htaccess maintenance after upgrade
# *_FILE variants for secrets  - For sensitive values, use *_FILE pattern with Docker secrets
###############################################################################

###############################################################################
# Utility Functions
###############################################################################

# The entrypoint command's first argument
ENTRYPOINT_ARGV1="${1:-}"

# OCC
# Command for running `occ`
OCC="php /var/www/html/occ"

###############################################################################
# version_greater
# Compare two version strings (A and B).
# Arguments:
#   $1: Version string A
#   $2: Version string B
# Returns: 0 (true) if version A is greater than B; 1 (false) otherwise.
###############################################################################
version_greater() {
    [ "$(printf '%s\n' "$@" | sort -t '.' -n -k1,1 -k2,2 -k3,3 -k4,4 | head -n 1)" != "$1" ]
}

###############################################################################
# version_greater_major
# Compare major version numbers of two version strings.
# Arguments:
#   $1: Version string A (e.g., "18.0.4")
#   $2: Version string B (e.g., "16.0.7")
#   $3: Delta (e.g., 1 for "at most one major ahead")
# Returns: 0 (true) if major version of A > major version of B + delta; 1 (false) otherwise.
###############################################################################
version_greater_major() {
    major_a="${1%%.*}"
    major_b="${2%%.*}"
    delta="${3:-0}"
    [ "$major_a" -gt "$((major_b + delta))" ]
}

###############################################################################
# directory_empty
# Check if a directory is empty.
# Arguments:
#   $1: Directory path.
# Returns: 0 (true) if directory is empty; 1 (false) otherwise.
###############################################################################
directory_empty() {
    [ -z "$(ls -A "$1/")" ]
}

###############################################################################
# is_root
# Check if the current process is running as root.
# Arguments: none (uses $uid global).
# Returns: 0 (true) if running as root (UID 0), 1 (false) otherwise.
###############################################################################
is_root() {
    [ "$uid" -eq 0 ]
}

###############################################################################
# is_apache
# Check if the script's first argument indicates Apache.
# Arguments: none (uses ENTRYPOINT_ARGV1).
# Returns: 0 (true) if $1 matches "apache" or starts with "apache2", 1 (false) otherwise.
###############################################################################
is_apache() {
    case "$ENTRYPOINT_ARGV1" in
        apache|apache2*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

###############################################################################
# is_php_fpm
# Check if the script's first argument indicates PHP-FPM.
# Arguments: none (uses ENTRYPOINT_ARGV1).
# Returns: 0 (true) if $1 starts with "php-fpm", 1 (false) otherwise.
###############################################################################
is_php_fpm() {
    case "$ENTRYPOINT_ARGV1" in
        php-fpm*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

###############################################################################
# set_user_group
# Sets global $user and $group variables according to the entrypoint command and UID/GID context.
# Arguments: none. Uses is_root, is_apache, is_php_fpm, $APACHE_RUN_USER, $APACHE_RUN_GROUP, $uid, $gid.
# Sets: $user, $group, $uid, $gid.
###############################################################################
set_user_group() {
    user='www-data'
    group='www-data'
    uid="$(id -u)"
    gid="$(id -g)"

    if is_root; then
        if is_apache; then
            user="${APACHE_RUN_USER:-www-data}"
            group="${APACHE_RUN_GROUP:-www-data}"
            # Apache config may specify user/group as "#1000", so remove leading '#' if present
            user="${user#'#'}"
            group="${group#'#'}"
        elif is_php_fpm; then
            user='www-data'
            group='www-data'
        fi
    else
        user="$uid"
        group="$gid"
    fi
}

###############################################################################
# configure_redis_session_handler
# Configures PHP sessions to use Redis if REDIS_HOST is set.
# Arguments: none. Uses env vars.
###############################################################################
configure_redis_session_handler() {
    if [ -n "${REDIS_HOST+x}" ]; then
        echo "Configuring Redis as session handler"

        file_env REDIS_HOST_PASSWORD

        # Determine the prefix for REDIS_HOST to decide between Unix socket and TCP connection
        first_char=$(printf '%s' "$REDIS_HOST" | cut -c1-1)
        if [ "$first_char" = "/" ]; then
            # Using Unix socket for Redis connection
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
            # Using TCP connection with password
            if [ -n "${REDIS_HOST_USER+x}" ]; then
                redis_save_path="tcp://${REDIS_HOST}:${REDIS_HOST_PORT:=6379}?auth[]=${REDIS_HOST_USER}&auth[]=${REDIS_HOST_PASSWORD}"
            else
                redis_save_path="tcp://${REDIS_HOST}:${REDIS_HOST_PORT:=6379}?auth=${REDIS_HOST_PASSWORD}"
            fi
        else
            # Using TCP connection without password
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
}

###############################################################################
# get_nextcloud_versions
# Sets installed_version and image_version variables.
# - installed_version: detected from /var/www/html/version.php or set to 0.0.0.0 if not present
# - image_version: detected from /usr/src/nextcloud/version.php
# Arguments: none
# Globals set: installed_version, image_version
###############################################################################
get_nextcloud_versions() {
    # Default value used to indicate a new install
    installed_version="0.0.0.0"
    if [ -f /var/www/html/version.php ]; then
        # TODO: Improve error handling in case of syntax errors/missing $OC_Version/etc
        # shellcheck disable=SC2016
        installed_version="$(php -r 'require "/var/www/html/version.php"; echo implode(".", $OC_Version);')"
    fi

    # TODO: Improve error handling here too (though far less likely to fail)
    # shellcheck disable=SC2016
    image_version="$(php -r 'require "/usr/src/nextcloud/version.php"; echo implode(".", $OC_Version);')"
}

###############################################################################
# is_installed
# Returns 0 (true) if Nextcloud is installed (installed_version is not 0.0.0.0), else 1 (false)
# Arguments: none. Uses global $installed_version.
###############################################################################
is_installed() {
    [ "$installed_version" != "0.0.0.0" ]
}

###############################################################################
# run_as
# Run a command as the specified user if running as root, otherwise as current user.
# Arguments:
#   $1: Command string to execute.
# Globals:
#   user - Username to switch to (when running as root).
# Returns: the exit code of the executed command.
###############################################################################
run_as() {
    if is_root; then
        su -p "$user" -s /bin/sh -c "$1"
    else
        sh -c "$1"
    fi
}

###############################################################################
# run_path
# Execute all executable .sh files in the specified hook folder, in alphanumeric order.
# Arguments:
#   $1: Name of the hook folder inside /docker-entrypoint-hooks.d/
# Returns: 0 on success; exits the script on any hook failure.
###############################################################################
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

###############################################################################
# file_env
# Load an environment variable from a file if available (supporting Docker secrets).
# Arguments:
#   $1: Name of the environment variable.
#   $2: (Optional) Default value if not set.
# Returns: Sets the environment variable named by $1.
# Supports Docker secrets by allowing *_FILE environment variables for sensitive values.
###############################################################################
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
# rsync
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
rsync() {
    if is_root; then
        set -- -rlDog --chown "$user:$group" "$@"
    else
        set -- -rlD "$@"
    fi
    command rsync "$@"
}

###############################################################################
# copy_if_missing_or_empty
# Copy a directory from source to destination if missing or empty.
# Arguments:
#   $1: Directory name
#   $2: Source base path
#   $3: Destination base path
# We only copy these directories if they're missing or empty, to avoid overwriting
# user data. This is especially important for config and data directories.
###############################################################################
copy_if_missing_or_empty() {
    dir="$1"
    src="$2"
    dest="$3"
    if [ ! -d "$dest/$dir" ] || directory_empty "$dest/$dir"; then
        rsync --include "/$dir/" --exclude '/*' "$src/" "$dest/"
    fi
}

###############################################################################
# set_trusted_domains
# Configure Nextcloud trusted domains from environment variable.
# Arguments: none (uses NEXTCLOUD_TRUSTED_DOMAINS global)
# Trusted domains are set during installation. Changing them after install may break existing clients.
###############################################################################
set_trusted_domains() {
    if [ -n "${NEXTCLOUD_TRUSTED_DOMAINS+x}" ]; then
        # turn off glob
        set -f
        NC_TRUSTED_DOMAIN_IDX=1
        for DOMAIN in ${NEXTCLOUD_TRUSTED_DOMAINS}; do
            DOMAIN=$(echo "${DOMAIN}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
            run_as \
                "$OCC config:system:set trusted_domains $NC_TRUSTED_DOMAIN_IDX --value=\"${DOMAIN}\""
            NC_TRUSTED_DOMAIN_IDX=$((NC_TRUSTED_DOMAIN_IDX+1))
        done
        # turn glob back on
        set +f
    fi
}

###############################################################################
# show_disabled_apps
# Display apps disabled after upgrade.
# Arguments: none (uses /tmp/list_before and /tmp/list_after)
###############################################################################
show_disabled_apps() {
    echo "The following apps have been disabled:"
    diff /tmp/list_before /tmp/list_after \
        | grep '<' | cut -d- -f2 | cut -d: -f1
    rm -f /tmp/list_before /tmp/list_after
}

###############################################################################
# warn_config_diffs
# Warn if config files in persistent storage differ from image defaults.
# Arguments: none.
###############################################################################
warn_config_diffs() {
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
}

###############################################################################
# assemble_db_install_options
# Sets database related install_options for the Nextcloud installer, and set trigger_installer flag if config is sufficient.
# Arguments: none (uses env vars)
# Sets: install_options (global), trigger_installer (global)
###############################################################################
assemble_db_install_options() {
    
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
        # We have enough for the automated installer; indicate we can bypass the Installation Wizard
        trigger_installer=true
    elif [ -n "${MYSQL_DATABASE+x}" ] && [ -n "${MYSQL_USER+x}" ] && [ -n "${MYSQL_PASSWORD+x}" ] && [ -n "${MYSQL_HOST+x}" ]; then
        echo "Installing with MySQL database"
        install_options="$install_options \
            --database mysql \
            --database-name \"$MYSQL_DATABASE\" \
            --database-user \"$MYSQL_USER\" \
            --database-pass \"$MYSQL_PASSWORD\" \
            --database-host \"$MYSQL_HOST\""
        # We have enough for the automated installer; indicate we can bypass the Installation Wizard
        trigger_installer=true
    elif [ -n "${POSTGRES_DB+x}" ] && [ -n "${POSTGRES_USER+x}" ] && [ -n "${POSTGRES_PASSWORD+x}" ] && [ -n "${POSTGRES_HOST+x}" ]; then
        echo "Installing with PostgreSQL database"
        install_options="$install_options \
            --database pgsql \
            --database-name \"$POSTGRES_DB\" \
            --database-user \"$POSTGRES_USER\" \
            --database-pass \"$POSTGRES_PASSWORD\" \
            --database-host \"$POSTGRES_HOST\""
        # We have enough for the automated installer; indicate we can bypass the Installation Wizard
        trigger_installer=true
    fi
}

###############################################################################
# run_nextcloud_installer
# Runs the Nextcloud command-line installer with retry logic for DB startup delays.
# Arguments:
#   $1: install options string (quoted)
# Globals:
#   OCC, user
###############################################################################
run_nextcloud_installer() {
    echo "Starting nextcloud installation"
    # Retry Nextcloud installation up to 10 times to handle possible database startup delays
    # TODO:
    # - Handle this better somehow and/or handle upstream.
    # - Confirm these retries are still even needed.
    max_retries=10
    try=0
    until [ "$try" -gt "$max_retries" ] || run_as \
        "$OCC maintenance:install $1"
    do
        echo "Retrying install..."
        try=$((try+1))
        sleep 10s
    done
    if [ "$try" -gt "$max_retries" ]; then
        echo "Installation of nextcloud failed!"
        exit 1
    fi
}

###############################################################################
# Main Entrypoint Logic
###############################################################################

# Permit disabling of the Apache remoteip configuration.
if is_apache && [ -n "${APACHE_DISABLE_REWRITE_IP+x}" ]; then
    echo "Disabling Apache IP rewrite (APACHE_DISABLE_REWRITE=1 specified)"
    echo "See https://github.com/nextcloud/docker?tab=readme-ov-file#using-the-image-behind-a-reverse-proxy-and-specifying-the-server-host-and-protocol"
    a2disconf remoteip
fi

# Warn if default entrypoint cmd parameter was overriden since it disables upgrades
# TODO: This belongs above the prior block, but this avoids a possible BC (though unlikely).
if ! is_apache && ! is_php_fpm && [ "${NEXTCLOUD_UPDATE:-0}" -eq 0 ]; then
    echo "NOTICE: Skipping upgrades and installation because default command overridden and NEXTCLOUD_UPDATE is not set to 1."
    echo "See https://github.com/nextcloud/docker/?tab=readme-ov-file#image-specific"
fi

# As long as we're running normally (or NEXTCLOUD_UPDATE was specified), proceed as normal
if is_apache || is_php_fpm || [ "${NEXTCLOUD_UPDATE:-0}" -eq 1 ]; then

    # Populate global $user / $group / $uid / $gid variables according to the entrypoint command and UID/GID context.
    set_user_group
    # Configure PHP sessions to use Redis if configured
    configure_redis_session_handler

    # Guard against starting if another instance is running and already upgrading/initializing Nextcloud
    # - This may happen in Kubernetes or other orchestrated environments with parallel startup.
    (
        # Use flock to prevent concurrent initialization.
        if ! flock -n 9; then
            echo "Another process is initializing Nextcloud. Waiting..."
            flock 9
        fi

        # Get Nextcloud versions (installed and image)
        get_nextcloud_versions

        # Guard against Downgrading.
        # - Prevent container startup if persisted code version is newer than image version.
        # - This indicates a downgrade attempt, which is not supported by image / Nextcloud.
        if is_installed && version_greater "$installed_version" "$image_version"; then
            echo "Can't start Nextcloud: data version ($installed_version) is higher than"
            echo "image version ($image_version); downgrading is not supported."
            echo "Are you sure you pulled a newer image version?"
            echo "See: https://github.com/nextcloud/docker/#update-to-a-newer-version"
            exit 1
        fi

        # Guard against major version jumps.
        # - Prevent container startup if image version is more than one major version higher than persisted code version.
        # - This indicates an overly aggressive major version jump attempt, which is not supported by image / Nextcloud.
        if is_installed && version_greater_major "$image_version" "$installed_version" 1; then
            echo "ERROR: Can't start Nextcloud: upgrading from $installed_version to $image_version is not supported."
            echo "You can upgrade only one major version at a time."
            echo "E.g., to upgrade from 14 to 16, first upgrade 14 to 15, then 15 to 16."
            echo "See: https://docs.nextcloud.com/server/latest/admin_manual/maintenance/upgrade.html"
            echo "See: https://github.com/docker-library/docs/tree/master/nextcloud#supported-tags-and-respective-dockerfile-links"
            exit 1
        fi

        # Instalization block.
        # - Initialization is only for new installs or upgrades.
        # - Bypassed if there's nothing to do
        if ! is_installed || version_greater "$image_version" "$installed_version"; then
            echo "Initializing nextcloud $image_version ..."

            # A prior version is already installed, and has been deemed within allowed upgrade jump range so proceed.
            if is_installed; then
                echo "Upgrading nextcloud from $installed_version ..."
                # Save pre-upgrade enabled/disabled apps list
                # TODO: Determine if tracking app list is still relevant
                run_as "$OCC app:list" | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_before
            fi

            # Code deployment block.
            # - Deploys image code onto the persistent storage volume
            # TODO: Move code deployment block (below) to its own function(s)

            ##########################################################################################
            # Why we copy Nextcloud code from the image to persistent storage...
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
            rsync \
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
            # We only copy these directories if they're missing or empty, to avoid overwriting
            # user data. This is especially important for config and data directories.
            #
            # TODO:
            #   - Consider updating only 'themes/' here, and move handling of 'config/', 'data/', and 'custom_apps/'
            #     into the install block. These directories should not be modified during a regular update/upgrade.
            #   - Review whether modifying these directories outside of installation could cause data loss or unexpected behavior.
            for dir in config data custom_apps themes; do
                copy_if_missing_or_empty \
                    "$dir" \
                    "/usr/src/nextcloud" \
                    "/var/www/html"
            done

             # Replace installed code's version.php with newer image code version
            rsync \
                --include '/version.php' \
                --exclude '/*' \
                /usr/src/nextcloud/ \
                /var/www/html/

            # Install block for fresh instances.
            # TODO: Consider moving install block to a dedicated function
            if ! is_installed; then
                echo "New nextcloud instance"

                # Base options for Nextcloud's command-line installer
                # TODO: Consider enabling verbose mode too
                install_options="--no-interaction"
                # Tracks whether we have enough automatic configuration parameters to bypass the Installation Wizard
                trigger_installer=false

                # Handle initial admin credentials (if provided)
                file_env NEXTCLOUD_ADMIN_USER
                file_env NEXTCLOUD_ADMIN_PASSWORD

                if [ -n "${NEXTCLOUD_ADMIN_USER+x}" ] && [ -n "${NEXTCLOUD_ADMIN_PASSWORD+x}" ]; then
                    install_options="$install_options \
                        --admin-user \"$NEXTCLOUD_ADMIN_USER\" \
                        --admin-pass \"$NEXTCLOUD_ADMIN_PASSWORD\""

                    if [ -n "${NEXTCLOUD_DATA_DIR+x}" ]; then
                        install_options="$install_options \
                            --data-dir \"$NEXTCLOUD_DATA_DIR\""
                    fi

                    # Assemble the database autoconfiguration options (if any)
                    assemble_db_install_options

                    # If all required configuration values are provided, run the Nextcloud command-line installer 
                    # automatically. Otherwise, skip the installer and require the user to complete setup through 
                    # the web-based Installation Wizard. Any missing configuration must be entered in the web UI.
                    if [ "$trigger_installer" = true ]; then
                    
                        # Trigger pre-installation hook scripts (if any)
                        run_path pre-installation

                        # Run the Nextcloud command-line installer
                        run_nextcloud_installer "$install_options"
                        
                        # Configure trusted domains (if specified).
                        # TODO: This could probably be moved elsewhere to permit reconfiguration within existing installs.
                        set_trusted_domains

                         # Trigger post-installation hook scripts (if any)
                        run_path post-installation
                    fi
                fi

                # Not enough parameters specified to do an automated installation.
                if [ "$trigger_installer" = false ]; then 
                    echo "Next step: Access your instance to finish the web-based installation!"
                    echo "Hint: Set NEXTCLOUD_ADMIN_USER, NEXTCLOUD_ADMIN_PASSWORD, and DB vars"
                    echo "before first launch to fully automate initial installation."
                fi

            # Upgrade path for existing instances.
            # TODO: Consider moving upgrade block to a dedicated function.
            else # (i.e. is_installed)
            
                # Trigger pre-upgrade hook scripts (if any)
                run_path pre-upgrade

                # Run Nextcloud database upgrades (and other non-code changes)
                run_as "$OCC upgrade"

                # Save post-upgrade enabled/disabled apps list.
                # This is used to determine if there were problematic app upgrades.
                run_as "$OCC app:list" | sed -n "/Enabled:/,/Disabled:/p" > /tmp/list_after
                # Show differences in post-upgrade enabled/disabled apps
                show_disabled_apps

                # Trigger post-upgrade hook scripts (if any)
                run_path post-upgrade
            fi

            echo "Initializing finished"
        fi

        # Update htaccess after init if requested
        if [ -n "${NEXTCLOUD_INIT_HTACCESS+x}" ] \
            && is_installed; then
            run_as "$OCC maintenance:update:htaccess"
        fi
    ) 9> /var/www/html/nextcloud-init-sync.lock

    warn_config_diffs
    run_path before-starting
fi

###############################################################################
# Handoff to Main Container Process
###############################################################################

exec "$@"
