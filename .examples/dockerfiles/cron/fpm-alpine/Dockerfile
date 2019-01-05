FROM nextcloud:fpm-alpine

RUN apk add --no-cache supervisor \
  && mkdir /var/log/supervisord /var/run/supervisord

COPY supervisord.conf /etc/supervisor/supervisord.conf

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord"]
