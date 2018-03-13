#!/bin/bash
set -e

exec busybox crond -f -l 0 -L /dev/stdout
