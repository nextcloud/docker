# Examples section

In this subfolders are some examples how to use the docker image. There are two sections:
 
 * [`dockerfiles`](https://github.com/nextcloud/docker/tree/master/.examples/dockerfiles)
 * [`docker-compose`](https://github.com/nextcloud/docker/tree/master/.examples/docker-compose)

The `dockerfiles` are derived images, that add or alter certain functionalities of the default docker images. In the `docker-compose` subfolder are examples for deployment of the application, including database, redis, collabora and other services.

## Dockerfiles
The Dockerfiles use the default images as base image and build on top of it.


Example | Description
------- | -------
[cron]() | uses supervisord to run the cron job inside the container (so no extra container is needed).
[imap]() | adds dependency to authentificate user via imap
[smb]() | adds dependency to use smb shares





## docker-compose
In `docker-compose` additional services are bundled to create a complete nextcloud installation. The examples are designed to run out-of-the-box.
Before running the examples you have to modify the `db.env` and `docker-compose` file and fill in your custum information.


**TODO: ADD INSECURE DESCRIPTION**


### with-nginx-proxy
The nginx proxy adds a proxy layer between nextcloud and the internet. The proxy is designed to serve multiple sites on the same host machine.
The advantage in adding this layer is the ability to add a container for [Let's Encrypt](https://letsencrypt.org/) certificate handling.
This combination of the [jwilder/nginx-proxy](https://github.com/jwilder/nginx-proxy) and [jrcs/docker-letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion) containers creates a fully automated https encryption of the nextcloud installation without worrying about certificate generation, validation or renewal.

To use this example complete the following steps:

1. open docker-compose.yml
  a. insert your nextcloud domain behind `VIRTUAL_HOST=`and `LETSENCRYPT_HOST=`
  b. enter a valid email behind `LETSENCRYPT_EMAIL`
  c. choose a root password for the database behin `MYSQL_ROOT_PASSWORD=`
  d. enter your collabora domain behind `domain=`
2. choose a password for the database user nextcloud in `db.env`behind `MYSQL_PASSWORD`
3. run `docker-compose build --pull` to pull the most recent base images and build the custom dockerfiles
4. start nextcloud with `docker-compose up -d`


If you want to update your installation to a newer version of nextcloud, repeat the steps 3 and 4.
