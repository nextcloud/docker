#!/bin/bash
set -e

mkdir -p /var/spool/cron/crontabs

exec busybox crond -f -l 0 -L /dev/stdout
