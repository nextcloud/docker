FROM php:7.0-fpm-alpine

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini

# Install PHP extensions
# https://docs.nextcloud.com/server/9/admin_manual/installation/source_installation.html
RUN set -ex \
  && apk update \
  && apk add build-base python-dev py-pip jpeg-dev jpeg \
     libldap openldap-dev zlib zlib-dev \
     freetype freetype-dev libjpeg-turbo libjpeg-turbo-dev \
     postgresql-dev libmcrypt-dev libmcrypt libpng-dev libpng \
     autoconf make g++ gcc git file gnupg re2c icu icu-dev tzdata \
  && docker-php-ext-configure gd \
     --with-freetype-dir=/usr/include/ \
     --with-png-dir=/usr/include \
     --with-jpeg-dir=/usr/include \
  && NPROC=$(getconf _NPROCESSORS_ONLN) \
  && docker-php-ext-install -j${NPROC} gd \
  && docker-php-ext-install exif intl mbstring mcrypt opcache \
     pdo_mysql pdo_pgsql pgsql zip ldap \
  && docker-php-ext-enable gd exif intl mbstring mcrypt opcache \
     pdo_mysql pdo_pgsql pgsql zip ldap \
  && pecl install APCu-5.1.6 \
  && git clone https://github.com/phpredis/phpredis.git \
  && cd phpredis \
  && git checkout php7 \
  && phpize \
  && ./configure \
  && make && make install \
  && cd .. \
  && rm -rf phpredis \
  && docker-php-ext-enable redis apcu \
  && apk del autoconf make g++ gcc git py-pip zlib-dev \
     jpeg-dev libmcrypt-dev libpng-dev openldap-dev \
     freetype-dev libjpeg-turbo-dev \
  && rm -rf /var/cache/apk/*

VOLUME /var/www/html

ENV NEXTCLOUD_VERSION 9.0.57

RUN curl -fsSL -o nextcloud.tar.bz2 \
    "https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" \
 && curl -fsSL -o nextcloud.tar.bz2.asc \
    "https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2.asc" \
 && export GNUPGHOME="$(mktemp -d)" \
 # gpg key from https://nextcloud.com/nextcloud.asc
 && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 28806A878AE423A28372792ED75899B9A724937A \
 && gpg --batch --verify nextcloud.tar.bz2.asc nextcloud.tar.bz2 \
 && rm -r "$GNUPGHOME" nextcloud.tar.bz2.asc \
 && tar -xjf nextcloud.tar.bz2 -C /usr/src/ \
 && rm nextcloud.tar.bz2

COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
