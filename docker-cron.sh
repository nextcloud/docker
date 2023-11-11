#!/bin/sh
set -eu

exec busybox crond -f -L /dev/stdout
