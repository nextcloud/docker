FROM php:7.1-apache

RUN set -ex \
  && buildDeps=" \
    rsync \
    libbz2-dev \
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
  " \
  && apt-get update \
  && apt-get install -y $buildDeps --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

# https://docs.nextcloud.com/server/12/admin_manual/installation/source_installation.html#prerequisites-for-manual-installation
RUN set -ex \
  && phpModules=" \
    bz2 \
    curl \
    gd \
    exif \
    intl \
    mbstring \
    mcrypt \
    ldap \
    mysqli \
    opcache \
    pdo_mysql \
    pdo_pgsql \
    pgsql \
    zip \
  " \
  && docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
  && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
  && docker-php-ext-install $phpModules

# set recommended PHP.ini settings
# see https://docs.nextcloud.com/server/12/admin_manual/configuration_server/server_tuning.html#enable-php-opcache
RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.enable_cli=1'; \
    echo 'opcache.interned_strings_buffer=8'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.save_comments=1'; \
    echo 'opcache.revalidate_freq=1'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini
RUN a2enmod rewrite

# PECL extensions
RUN set -ex \
 && pecl install APCu-5.1.8 \
 && pecl install memcached-3.0.2 \
 && pecl install redis-3.1.1 \
 && docker-php-ext-enable apcu redis memcached
RUN a2enmod rewrite

VOLUME /var/www/html
CMD ["apache2-foreground"]
