#!/usr/bin/env bash
# ##
# file name: start_container.sh_
# Author: Malanik Jan
# Email: malanik (_dot_) jan (_at_) gmail (_dot_) com
# Description: 
#   - Helper script to start Nextcloud container
# ##

set -x

NAME=''
NCD_VOL='/srv/nextcloud:/var/www/html:rprivate' 
#20190509 stable
TAG='16.0'

if [[ -z "${NCD_NAME}" ]]; then
  read -p "Would you like to handle apache/nginx/fpm? [nginx/apache/fpm]" NCD_NAME
fi
if [[ -z "${NCD_REMOVEIMAGE}" ]]; then
  read -p "Remove image? [y/n]" NCD_REMOVEIMAGE
fi
if [[ -z "${NCD_STARTCONTAINER}" ]]; then
  read -p "Start container? [y/n]" NCD_STARTCONTAINER
fi

if [[ "${NCD_STARTCONTAINER}" == 't' ]] && [[ -z "${NCD_STARTSLEEP}" ]]; then
  read -p "Do you want to start with /bin/sleep infinity? [y/n]" NCD_STARTSLEEP
fi

echo "Starting script with configuration:" 
for var in $(env | grep NCD); do
  echo ${var} 
done
NCD_NAME="${TAG}-${NCD_NAME}"
IMAGE="1john2ci/nextcloud:${NCD_NAME}"

declare -A PUBLISH=(
[16.0-nginx]=' -p 127.0.0.1:8060:80 '
[fpm-ncd]=''
)

# ##
# Cleanup
# ##
docker stop "${NCD_NAME}"
docker rm "${NCD_NAME}"
if [ "${NCD_REMOVEIMAGE}" == 'y' ]; then
  docker rmi "${IMAGE}" 
fi

if [ "${NCD_STARTCONTAINER}" != 'y' ] ; then
  exit 0
fi
# ##
# Start Container
# ##
if [ "${NCD_STARTSLEEP}" == 'y' ]; then
  EXECCMD='/bin/sleep infinity'
else
  EXECCMD=''
fi
eval "CMD='docker run -dit \
    --hostname "${NCD_NAME}" \
    --name "${NCD_NAME}" \
    --net 'nextcloud' \
    --volume ${NCD_VOL} \
    "${PUBLISH[$NCD_NAME]}" \
    "${IMAGE}" \
    "${EXECCMD}" \
  '"

${CMD}
