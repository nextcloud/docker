FROM nextcloud:32

RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    pkg-config \
    libmemcached-dev \
    zlib1g-dev \
 && pecl install memcached redis \
 && docker-php-ext-enable memcached redis \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*
