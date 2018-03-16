#!/bin/sh
set -eu

exec busybox crond -f -l 0 -L /dev/stdout
