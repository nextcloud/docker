#!/bin/sh
set -eu

exec busybox crond -f -l ${NEXTCLOUD_CRON_LOG_LEVEL:-0} -L /dev/stdout
