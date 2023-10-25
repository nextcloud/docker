#!/bin/sh
set -eu

exec busybox crond -f -l ${NEXTCLOUD_CRON_LOG_LEVEL:-8} -L /dev/stdout
