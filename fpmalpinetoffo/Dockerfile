FROM nextcloud/nextcloudtoffo:fpm-alpine
#WORKDIR /usr/src/app
RUN \
    echo "@main http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MIN_VERSION}/main" >> /etc/apk/reposito
    echo "@community http://dl-cdn.alpinelinux.org/alpine/v${ALPINE_MIN_VERSION}/community" >> /etc/ap
    echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN apk add --no-cache \
      rsync \
      bash \
      curl \
      libgcc \
      lksctp-tools \
      pcre \
      zlib-dev \
      dpkg-dev \
      dpkg \
      gcc \
      g++ \
      libc-dev \
      linux-headers \....
      tar \
      gcompat \
      libucontext \
      musl-obstack \
      libva-vdpau-driver \
      libvdpau \
      libx11 \
      nodejs \
      ghostscript \
      libbz2 \
      zlib \
      musl \
      mesa-dri-gallium \
      mesa-va-gallium \
      libva-intel-driver \
      perl \
      ffmpeg \
      imagemagick \
      procps \
      samba-client \
      supervisor \
#      libreoffice \
    ;
#COPY zz-docker.conf /usr/local/etc/
#COPY smtp.config.php /var/www/config/smtp.config.php
RUN apk add --no-cache supervisor \
  && mkdir /var/log/supervisord /var/run/supervisord
COPY supervisord.conf /
#ENV NEXTCLOUD_UPDATE=1
CMD ["/usr/bin/supervisord", "-c", "/supervisord.conf"]
