# What is Nextcloud?

[![Build Status update.sh](https://doi-janky.infosiftr.net/job/update.sh/job/nextcloud/badge/icon)](https://doi-janky.infosiftr.net/job/update.sh/job/nextcloud)
[![Build Status Travis](https://travis-ci.org/nextcloud/docker.svg?branch=master)](https://travis-ci.org/nextcloud/docker)

A safe home for all your data. Access & share your files, calendars, contacts, mail & more from any device, on your terms.

![logo](https://github.com/nextcloud/docker/raw/master/logo.png)

# How to use this image
This image is designed to be used in a micro-service environment. There are two versions of the image you can choose from.

The `apache` tag contains a full nextcloud installation including an apache web server. It is designed to be easy to use and get's you running pretty fast. This is also the default for the `latest` tag and version tags that are not further specified.

The second option is a `fpm` container. It is based on the [php-fpm](https://hub.docker.com/_/php/) image and runs a fastCGI-Process that serves your nextcloud page. To use this image it must be combined with any webserver that can proxy the http requests to the FastCGI-port of the container.

## Using the Apache image
The apache image contains a webserver and exposes port 80. However by default it is not configured to use ssl encryption (See below). To start the container type:

```console
$ docker run -d nextcloud
```

Now you can access Nextcloud at http://localhost/ from your host system. To make your nextcloud installation available from the internet you must map the port of the container to your host:

```console
$ docker run -p 80:80 -d nextcloud
```


## Using the fpm image
To use the fpm image you need an additional web server that can proxy http-request to the fpm-port of the container. For fpm connection this container exposes port 9000. In most cases you might want use another container or your host as proxy.
If you use your host you can address your nextcloud container directly on port 9000. If you use another container, make sure that you add them to the same docker network (via `docker run --network <NAME> ...` or a `docker-compose` file).
In both cases you don't want to map the fpm port to you host. 

```console
$ docker run -d nextcloud-fpm
```

As the fastCGI-Process is not capable of serving static files (style sheets, images, ...) the webserver needs access to these files. That can be achieved with the `volumes-from` option. You can find more information in the docker-compose section.

## Using an external database
By default this container uses SQLite for data storage, but the Nextcloud setup wizard (appears on first run) allows connecting to an existing MySQL/MariaDB or PostgreSQL database. You can also link a database container, e.g. `--link my-mysql:mysql`, and then use `mysql` as the database host on setup. More info is in the docker-compose section.

## Persistent data
The nextcloud installation and all data beyond what lives in the database (file uploads, etc) is stored in the [unnamed docker volume](https://docs.docker.com/engine/tutorials/dockervolumes/#adding-a-data-volume) volume `/var/www/html`. The docker daemon will store that data within the docker directory `/var/lib/docker/volumes/...`. That means your data is saved even if the container crashes, is stopped, updated or deleted.
To get access to your data for backups or migration you should use named docker volumes for the following folders:

- `-v apps:/var/www/html/apps` installed / modified apps
- `-v config:/var/www/html/config` local configuration
- `-v data:/var/www/html/data` the actual data of your Nextcloud

Additionally, if you use a database container you want a persistent database as well. Use this volume on your database container:

Mysql / MariaDB:
- `-v db:/var/lib/mysql` database files

PostegreSQL:
- `-v db:/var/lib/postresql/data` database files 



# Running this image with docker-compose
The easiest way to get a fully featured and functional setup is using a `docker-compose` file. There are too many different possibilities to setup your system, so here are only some examples what you have to look for. 

At first make sure you have chosen the right base image (fpm or apache) and added the features you wanted (see at adding features). In almost every case you want to add a database container and https encryption to your setup. You also want to add docker volumes to get persistent data. 

## Base version - Apache
This version will use the apache image and add a mariaDB container. The volumes are set to keep your data persistent.

```yaml
version: '2'

volumes:
  apps:
  config:
  data:
  db:

services:
  db:
    image: mariadb
    restart: always
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PW=...
      - MYSQL_USER_PW=...
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud

  web:  
    image: nextcloud
    ports:
      - "80:80"
    links:
      - db
    volumes:
      - data:/var/www/html/data
      - config:/var/www/html/config
      - apps:/var/www/html/apps
    restart: always

```

## Base version - FPM
When using the FPM image you need another container that acts as web server on port 80 and proxies the requests to the nextcloud container. In this example a simple nginx container is used. Like above, a database container is added and the data is stored in docker volumes.
For the nginx container you need a configuration file `nginx.conf`, that is located next to the docker-compose file and mounted into the container. An example can be found in the examples section [here](https://github.com/nextcloud/docker/tree/master/.examples).

```yaml
version: '2'

volumes:
  apps:
  config:
  data:
  db:

services:
  db:
    image: mariadb
    restart: always
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PW=...
      - MYSQL_USER_PW=...
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud

  app:
    image: nextcloud
    links:
      - db
    volumes:
      - data:/var/www/html/data
      - config:/var/www/html/config
      - apps:/var/www/html/apps
    restart: always

  web:
    image: nginx
    ports:
      - "80:80"
    links:
      - app
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    volumes-from:
      - app
    restart: always
```

## First use
When you first access your nextcloud, the setup wizard will appear and ask you to choose an administrator account and password and the database connection. For the database use `db` as host and `nextcloud` as table and user name. Also enter the password you chose in the compose file.

## SSL encryption
Until here, we haven't talked about encrypting the connection between your nextcloud host and the clients. Using up-to-date encryption is mandatory if your host is reachable from the internet. There are many different possibilities to introduce encryption. 

An easy and free way to get certificates that are accepted by the browsers is [Let's Encrypt](https://letsencrypt.org/). The great thing about it is, that the whole certificate generation / validation is fully automated and certificate renewals are also very easy. 
To integrate Let's Encrypt, we recommend using a reverse proxy in front of our nextcloud installation. Your nextcloud will only be reachable through the proxy, which encrypts all traffic to the clients. See our [examples](https://github.com/nextcloud/docker/tree/master/.examples) to get an idea how it works.


# Update to a newer version
Updating can be done in two ways. The easy solution is running the web-updater. While this should work it can cause problems, because the underlying container image will get outdated. A better solution is updating like docker intended. That means pulling the new image, throw away the old container and start a new one. The startup script will handle updating your data for you.

```console
$ docker pull nextcloud
$ docker run -d nextcloud
```

When using docker-compose:

```console
$ docker-compose up -d --pull
```


# Adding Features
A lot of people use additional functionality inside their nextcloud installation. If the image does not include the packages you need, you can easily build your own image on top of it.
The [examples folder](https://github.com/nextcloud/docker/blob/master/.examples) gives a few examples on how to add certain functionalities, like including the cron job, smb-support or imap-authentication. 
Start your derived image with the `FROM` statement and add whatever you like.

```yaml
FROM nextcloud:apache

RUN ...

```

If you use your own Dockerfile you need to configure your docker-compose file accordingly. Switch out the `image` option with `build`. You have to specify the path to your Dockerfile. (in the example it's in the same directory next to the docker-compose file)

```yml
  app:
    build: .
    links:
      - db
    volumes:
      - data:/var/www/html/data
      - config:/var/www/html/config
      - apps:/var/www/html/apps
    restart: always
```

Updating your own derived image is also very simple. When a new version of the nextcloud image is available run:

```console
docker build -t your-name --pull . 
docker run -d your-name

```

or for docker-compose:

```console
docker-compose build --pull
docker-compose up -d

```

# Questions / Issues
If you got any questions or problems using the image, please visit our [Github Repository](https://github.com/nextcloud/docker) and write an issue.  
