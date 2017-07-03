FROM php:5.6-fpm

RUN apt-get update && apt-get install -y \
  rsync \
  bzip2 \
  libcurl4-openssl-dev \
  libfreetype6-dev \
  libicu-dev \
  libjpeg-dev \
  libldap2-dev \
  libmcrypt-dev \
  libmemcached-dev \
  libpng12-dev \
  libpq-dev \
  libxml2-dev \
  && rm -rf /var/lib/apt/lists/*

# https://docs.nextcloud.com/server/9/admin_manual/installation/source_installation.html
RUN debMultiarch="$(dpkg-architecture --query DEB_BUILD_MULTIARCH)" \
  && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
  && docker-php-ext-configure ldap --with-libdir="lib/$debMultiarch" \
  && docker-php-ext-install gd exif intl mbstring mcrypt ldap mysql opcache pdo_mysql pdo_pgsql pgsql zip

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

# PECL extensions
RUN set -ex \
 && pecl install APCu-4.0.10 \
 && pecl install memcached-2.2.0 \
 && pecl install redis-2.2.8 \
 && docker-php-ext-enable apcu redis memcached

ENV NEXTCLOUD_VERSION 10.0.5
VOLUME /var/www/html

COPY config/* /usr/src/nextcloud/config/

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
 && rm nextcloud.tar.bz2 \
 && rm -rf /usr/src/nextcloud/updater \
 # https://docs.nextcloud.com/server/11/admin_manual/installation/installation_wizard.html#setting-strong-directory-permissions
 && mkdir -p /usr/src/nextcloud/data \
 && mkdir -p /usr/src/nextcloud/custom_apps \
 && find /usr/src/nextcloud/ -type f -print0 | xargs -0 chmod 0640 \
 && find /usr/src/nextcloud/ -type d -print0 | xargs -0 chmod 0750 \
 && chown -R root:www-data /usr/src/nextcloud/ \
 && chown -R www-data:www-data /usr/src/nextcloud/custom_apps/ \
 && chown -R www-data:www-data /usr/src/nextcloud/config/ \
 && chown -R www-data:www-data /usr/src/nextcloud/data/ \
 && chown -R www-data:www-data /usr/src/nextcloud/themes/ \
 && chmod +x /usr/src/nextcloud/occ

COPY docker-entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
