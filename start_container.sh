#!/usr/bin/env bash
# ##
# file name: start_ncd.sh
# Author: Malanik Jan
# Email: malanik (_dot_) jan (_at_) gmail (_dot_) com
# Description: 
#   - Helper script to start Nextcloud container
# ##

set -x

NAME=''
NCD_VOL='/srv/nextcloud:/var/www/html:rprivate' 
TAG='20190509'

read -p "Would you like to handle apache/nginx/fpm? [nginx/apache/fpm]" NAME
read -p "Remove image? [y/n]" REMOVEIMAGE
read -p "Start container? [y/n]" STARTCONTAINER
if [ "${STARTCONTAINER}" == 'y' ]; then
  read -p "Do you want to start with /bin/sleep infinity? [y/n]" STARTSLEEP
fi

IMAGE="1john2ci/nextcloud:${NAME}-ncd-${TAG}"
NAME="${NAME}-ncd"

declare -A PUBLISH=(
[nginx-ncd]=' -p 127.0.0.1:8060:80 '
[fpm-ncd]=''
)

# ##
# Cleanup
# ##
docker stop "${NAME}"
docker rm "${NAME}"
if [ "${REMOVEIMAGE}" == 'y' ]; then
  docker rmi "${IMAGE}" 
fi

if [ "${STARTCONTAINER}" != 'y' ] ; then
  exit 0
fi
# ##
# Start Container
# ##
if [ "${STARTSLEEP}" == 'y' ]; then
  EXECCMD='/bin/sleep infinity'
else
  EXECCMD=''
fi
eval "CMD='docker run -dit \
    --hostname "${NAME}" \
    --name "${NAME}" \
    --net 'nextcloud' \
    --volume ${NCD_VOL} \
    "${PUBLISH[$NAME]}" \
    "${IMAGE}" \
    "${EXECCMD}" \
  '"
export SQLITE_DATABASE='test'
export NEXTCLOUD_ADMIN_USER='admin'
export NEXTCLOUD_ADMIN_PASSWORD='admin'

${CMD}
