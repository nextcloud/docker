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

When nextcloud is updated the source files and some system apps, that are shipped with the nextcloud installation are overwritten.
To backup your nextcloud installation, you have to take care of five parts: data, config, apps, theming and database. 
The data and config are stored in respective subfolders inside `/var/www/html/`. The apps are split into system apps (wich are shipped with nextcloud and you don't need to take care of) and a `custom_apps` folder. If you use theming you can apply your theming into the `theming` folder.

Overview of the folders:

- `/var/www/html/custom_apps` installed / modified apps
- `/var/www/html/config` local configuration
- `/var/www/html/data` the actual data of your Nextcloud
- `/var/www/html/theming` theming/branding

And if you use an external database you need the following folders on your database container:

Mysql / MariaDB:
- `/var/lib/mysql` database files

PostegreSQL:
- `db:/var/lib/postresql/data` database files 


To get access to your data for backups or migration you can use named docker volumes or mount host folders:

Nextcloud:
```console
$ docker run -d nextcloud \
-v apps:/var/www/html/custom_apps \
-v config:/var/www/html/config \
-v data:/var/www/html/data \
-v theming:/var/www/html/theming
```

Database:
```console
$ docker run -d mariadb \
-v db:/var/lib/mysql
```


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

  app:  
    image: nextcloud
    ports:
      - "80:80"
    links:
      - db
    volumes:
      - data:/var/www/html/data
      - config:/var/www/html/config
      - apps:/var/www/html/custom_apps
    restart: always

```

## Base version - FPM
When using the FPM image you need another container that acts as web server on port 80 and proxies the requests to the nextcloud container. In this example a simple nginx container is used. Like above, a database container is added and the data is stored in docker volumes.
The nginx container also need access to static files from your nextcloud installation. It gets access to all the volumes mounted to nextcloud via the `volumes_from` option.
The configuration for nginx is stored in the configuration file `nginx.conf`, that is located next to the docker-compose file and mounted into the container. An example can be found in the examples section [here](https://github.com/nextcloud/docker/tree/master/.examples).

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
      - apps:/var/www/html/custom_apps
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
When you first access your nextcloud, the setup wizard will appear and ask you to choose an administrator account, password and the database connection. For the database use `db` as host and `nextcloud` as table and user name. Also enter the password you chose in the compose file.

## SSL encryption
Until here, we haven't talked about encrypting the connection between your nextcloud host and the clients. Using up-to-date encryption is mandatory if your host is reachable from the internet. There are many different possibilities to introduce encryption. 

An easy and free way to get certificates that are accepted by the browsers is [Let's Encrypt](https://letsencrypt.org/). The whole certificate generation / validation is fully automated and certificate renewals are also very easy. 
To integrate Let's Encrypt, we recommend using a reverse proxy in front of our nextcloud installation. Your nextcloud will only be reachable through the proxy, which encrypts all traffic to the clients. See our [examples](https://github.com/nextcloud/docker/tree/master/.examples) to get an idea how it works.


# Update to a newer version
Updating the nextcloud container is done by pulling the new image and throwing away the old container. Since all data is stored in volumes nothing gets lost. The startup script will check for the version in your data and the installed docker version. If it finds a mismatch, it automatically starts the upgrade process. 

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

```yaml
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

The `--pull` option tells docker to look for new versions of the base image. The build instructions inside your `Dockerfile` are run on top of the new image.

# Migrating an existing installation
You're already using nextcloud and want to switch to docker? Great! Here are some things to look out for:

* Define your whole nextcloud instance in a `docker-compose` file and run it with `docker-compose up -d` to get the base installation, volumes and database. Work from there.
* Restoring your database from a mysqldump (nextcloud\_db\_1 is the name of your db container; typically [folder name of the compose file]\_db\_1 -> if your compose file is in the folder nextcloud then it is nextcloud\_db\_1)
```console
docker cp ./database.dmp nextcloud_db:/dmp
docker-compose exec db sh -c "mysql -u USER -pPASSWORD nextcloud < /dmp"
docker-compose exec db rm /dmp
```
* Edit your config.php
  * Set database connection 
  ```php
  'dbhost' => 'db:3306',
  ``` 
  * Make sure you have no configuration for the `apps_paths`. Delete lines like these
  ```diff
  - "apps_paths" => array (
  -    0 => array (
  -            "path"     => OC::$SERVERROOT."/apps",
  -            "url"      => "/apps",
  -            "writable" => true,
  -    ),
  ```
  * Make sure your data directory is set to /var/www/html/data
  ```php
  'datadirectory' => '/var/www/html/data',
  ```
 

* Copy your data (nextcloud_data is the name of your nextcloud container; typically [folder name of the compose file]\_app\_1 -> if your compose file is in the folder nextcloud then it is nextcloud\_app\_1):
```console
docker cp ./data/ nextcloud_data:/var/www/html/data
docker-compose exec app chown www-data:www-data /var/www/html/data
docker cp ./theming/ nextcloud_data:/var/www/html/theming
docker-compose exec app chown www-data:www-data /var/www/html/theming
docker cp ./config/config.php nextcloud_data:/var/www/html/config
docker-compose exec app chown www-data:www-data /var/www/html/config
```
* Copy only the custom apps you use (or if you just use the store simply redownload them from the web interface):
```console 
docker cp ./apps/ nextcloud_data:/var/www/html/custom_apps
docker-compose exec app chown www-data:www-data /var/www/html/custom_apps
```

# Questions / Issues
If you got any questions or problems using the image, please visit our [Github Repository](https://github.com/nextcloud/docker) and write an issue.  
