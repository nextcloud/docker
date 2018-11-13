#!/bin/sh
set -eu

exec busybox crond -b -l 0 -L /dev/stdout
