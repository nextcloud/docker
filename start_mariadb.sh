#!/usr/bin/env bash
# ##
# file name: star_mariadb.sh
# Author: Malanik Jan
# Email: malanik (_dot_) jan (_at_) gmail (_dot_) com
# Description: 
#   - Helper script to start Mariadb
# ##

set -x

MARIA_NAME='mariadb'
MARIA_VOL='/srv/mariadb:/var/lib/mysql:rprivate' 
MARIA_TAG='10.4.4-bionic'
MARIA_IMAGE="${MARIA_NAME}:${MARIA_TAG}"

docker stop "${MARIA_NAME}"
docker rm "${MARIA_NAME}"

eval "CMD='docker run -dit \
    --hostname "${MARIA_NAME}" \
    --name "${MARIA_NAME}" \
    --net 'nextcloud' \
    --volume ${MARIA_VOL} \
    -e MYSQL_ROOT_PASSWORD='mariadb_admin' \
    -e MYSQL_DATABASE='nextcloud' \
    -e MYSQL_USER='ncd_admin' \
    -e MYSQL_PASSWORD='ncd_admin' \
    "${MARIA_IMAGE}"
  '"
${CMD}
