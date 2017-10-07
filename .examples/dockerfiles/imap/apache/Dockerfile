FROM nextcloud:apache

RUN apt-get update \
 && apt-get install -y libc-client-dev libkrb5-dev \
 && rm -rf /var/lib/apt/lists/* \
 && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
 && docker-php-ext-install imap
