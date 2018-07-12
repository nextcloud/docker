#!/bin/sh
set -eu

if [ "$(id -u)" = 0 ]; then
	>&2 echo 'Warning - Running as root is not recommended for security reasons.'
fi

if ! id -nu >/dev/null 2>&1; then
	# If there is no entry for the running user ID in the UNIX password file,
	# provide an identity for the user
  if [ -w /etc/passwd ]; then
		cat /etc/passwd > /tmp/passwd
    echo "nextcloud:x:$(id -u):0:Nextcloud user:/root:/sbin/nologin" >> /tmp/passwd
		cat /tmp/passwd > /etc/passwd
	  rm /tmp/passwd
  fi
fi
exec "$@"
