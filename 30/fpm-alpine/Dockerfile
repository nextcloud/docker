# DO NOT EDIT: created by update.sh from Dockerfile-alpine.template
FROM php:8.2-fpm-alpine3.21

# Define the commit hash for imagick as a variable
ENV IMAGICK_COMMIT_HASH d7d3c24af1b4f599897408f1714600b69a56473b

# entrypoint.sh and cron.sh dependencies
RUN set -ex; \
    \
    apk add --no-cache \
        imagemagick \
        imagemagick-pdf \
        imagemagick-jpeg \
        imagemagick-raw \
        imagemagick-tiff \
        imagemagick-heic \
        imagemagick-webp \
        imagemagick-svg \
        rsync \
    ; \
    \
    rm /var/spool/cron/crontabs/root; \
    echo '*/5 * * * * php -f /var/www/html/cron.php' > /var/spool/cron/crontabs/www-data

# install the PHP extensions we need
# see https://docs.nextcloud.com/server/stable/admin_manual/installation/source_installation.html
RUN set -ex; \
    \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        autoconf \
        freetype-dev \
        gmp-dev \
        icu-dev \
        imagemagick-dev \
        libevent-dev \
        libjpeg-turbo-dev \
        libmcrypt-dev \
        libmemcached-dev \
        libpng-dev \
        libwebp-dev \
        libxml2-dev \
        libzip-dev \
        openldap-dev \
        pcre-dev \
        postgresql-dev \
    ; \
    \
    docker-php-ext-configure ftp --with-openssl-dir=/usr; \
    docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp; \
    docker-php-ext-configure ldap; \
    docker-php-ext-install -j "$(nproc)" \
        bcmath \
        exif \
        ftp \
        gd \
        gmp \
        intl \
        ldap \
        opcache \
        pcntl \
        pdo_mysql \
        pdo_pgsql \
        sysvsem \
        zip \
    ; \
    \
# The master version on the imagick repository is compatible with PHP 8.3. However, the PECL version is not updated yet.
# As soon as it will get updated, we can switch back to the PECL version, instead of having this workaround.
    curl -fsSL -o imagick.tar.gz "https://github.com/Imagick/imagick/archive/$IMAGICK_COMMIT_HASH.tar.gz"; \
    tar -xzf imagick.tar.gz -C /tmp; \
    rm imagick.tar.gz; \
    cd "/tmp/imagick-$IMAGICK_COMMIT_HASH"; \
    sed -i "s/@PACKAGE_VERSION@/git-$(echo ${IMAGICK_COMMIT_HASH} | cut -c 1-7)/" php_imagick.h; \
    phpize; \
    ./configure; \
    make; \
    make install; \
    cd; \
    rm -r "/tmp/imagick-$IMAGICK_COMMIT_HASH"; \
    \
# pecl will claim success even if one install fails, so we need to perform each install separately
    pecl install APCu-5.1.24; \
    pecl install igbinary-3.2.16; \
    pecl install memcached-3.3.0 \
        --configureoptions 'enable-memcached-igbinary="yes"'; \
    pecl install redis-6.1.0 \
        --configureoptions 'enable-redis-igbinary="yes" enable-redis-zstd="yes" enable-redis-lz4="yes"'; \
    \
    docker-php-ext-enable \
        apcu \
        igbinary \
        imagick \
        memcached \
        redis \
    ; \
    rm -r /tmp/pear; \
    \
    runDeps="$( \
        scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
            | tr ',' '\n' \
            | sort -u \
            | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    )"; \
    apk add --no-network --virtual .nextcloud-phpext-rundeps $runDeps; \
    apk del --no-network .build-deps

# set recommended PHP.ini settings
# see https://docs.nextcloud.com/server/latest/admin_manual/installation/server_tuning.html#enable-php-opcache
ENV PHP_MEMORY_LIMIT 512M
ENV PHP_UPLOAD_LIMIT 512M
ENV PHP_OPCACHE_MEMORY_CONSUMPTION 128
RUN { \
        echo 'opcache.enable=1'; \
        echo 'opcache.interned_strings_buffer=32'; \
        echo 'opcache.max_accelerated_files=10000'; \
        echo 'opcache.memory_consumption=${PHP_OPCACHE_MEMORY_CONSUMPTION}'; \
        echo 'opcache.save_comments=1'; \
        echo 'opcache.revalidate_freq=60'; \
        echo 'opcache.jit=1255'; \
        echo 'opcache.jit_buffer_size=8M'; \
    } > "${PHP_INI_DIR}/conf.d/opcache-recommended.ini"; \
    \
    echo 'apc.enable_cli=1' >> "${PHP_INI_DIR}/conf.d/docker-php-ext-apcu.ini"; \
    \
    { \
        echo 'apc.serializer=igbinary'; \
        echo 'session.serialize_handler=igbinary'; \
    } >> "${PHP_INI_DIR}/conf.d/docker-php-ext-igbinary.ini"; \
    \
    { \
        echo 'memory_limit=${PHP_MEMORY_LIMIT}'; \
        echo 'upload_max_filesize=${PHP_UPLOAD_LIMIT}'; \
        echo 'post_max_size=${PHP_UPLOAD_LIMIT}'; \
    } > "${PHP_INI_DIR}/conf.d/nextcloud.ini"; \
    \
    mkdir /var/www/data; \
    mkdir -p /docker-entrypoint-hooks.d/pre-installation \
             /docker-entrypoint-hooks.d/post-installation \
             /docker-entrypoint-hooks.d/pre-upgrade \
             /docker-entrypoint-hooks.d/post-upgrade \
             /docker-entrypoint-hooks.d/before-starting; \
    chown -R www-data:root /var/www; \
    chmod -R g=u /var/www

VOLUME /var/www/html


ENV NEXTCLOUD_VERSION 30.0.7

RUN set -ex; \
    apk add --no-cache --virtual .fetch-deps \
        bzip2 \
        gnupg \
    ; \
    \
    curl -fsSL -o nextcloud.tar.bz2 "https://download.nextcloud.com/server/releases/nextcloud-30.0.7.tar.bz2"; \
    curl -fsSL -o nextcloud.tar.bz2.asc "https://download.nextcloud.com/server/releases/nextcloud-30.0.7.tar.bz2.asc"; \
    export GNUPGHOME="$(mktemp -d)"; \
# gpg key from https://nextcloud.com/nextcloud.asc
    gpg --batch --keyserver keyserver.ubuntu.com  --recv-keys 28806A878AE423A28372792ED75899B9A724937A; \
    gpg --batch --verify nextcloud.tar.bz2.asc nextcloud.tar.bz2; \
    tar -xjf nextcloud.tar.bz2 -C /usr/src/; \
    gpgconf --kill all; \
    rm nextcloud.tar.bz2.asc nextcloud.tar.bz2; \
    rm -rf "$GNUPGHOME" /usr/src/nextcloud/updater; \
    mkdir -p /usr/src/nextcloud/data; \
    mkdir -p /usr/src/nextcloud/custom_apps; \
    chmod +x /usr/src/nextcloud/occ; \
    apk del --no-network .fetch-deps

COPY *.sh upgrade.exclude /
COPY config/* /usr/src/nextcloud/config/

ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
