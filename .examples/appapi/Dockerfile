FROM nextcloud:stable-fpm

RUN apt-get update && apt-get install -y python3.13-venv pipx

ADD ./poetry.sh /tmp/poetry.sh

USER www-data
RUN pipx ensurepath
RUN python3 /tmp/poetry.sh

USER root
