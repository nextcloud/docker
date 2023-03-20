# Examples section

In this subfolders are some examples how to use the docker image. There are two sections:

 * [`dockerfiles`](https://github.com/nextcloud/docker/tree/master/.examples/dockerfiles)
 * [`docker-compose`](https://github.com/nextcloud/docker/tree/master/.examples/docker-compose)

The `dockerfiles` are derived images, that add or alter certain functionalities of the default docker images. In the `docker-compose` subfolder are examples for deployment of the application, including database, redis, collabora and other services.

## Dockerfiles
The Dockerfiles use the default images as base image and build on top of it.


Example | Description
------- | -------
[cron](https://github.com/nextcloud/docker/tree/master/.examples/dockerfiles/cron) | uses supervisor to run the cron job inside the container (so no extra container is needed). This image runs `supervisord` to start nextcloud and cron as two seperate processes inside the container.
[imap](https://github.com/nextcloud/docker/tree/master/.examples/dockerfiles/imap) | adds dependencies required to authenticate users via imap
[smb](https://github.com/nextcloud/docker/tree/master/.examples/dockerfiles/smb) | adds dependencies required to use smb shares
[full](https://github.com/nextcloud/docker/tree/master/.examples/dockerfiles/full) | adds dependencies for ALL optional packages and cron functionality via supervisor (as in the `cron` example Dockerfile).

### cron
NOTE: [this container must run as root or `cron.php` will not run](https://github.com/nextcloud/docker/issues/1899).

### full
The `full` Dockerfile example adds dependencies for all optional packages suggested by nextcloud that may be needed for some features (e.g. Video Preview Generation), as stated in the [Administration Manual](https://docs.nextcloud.com/server/latest/admin_manual/installation/source_installation.html).

NOTE: The Dockerfile does not install the LibreOffice package (line is commented), because it would increase the generated Image size by approximately 500 MB. In order to install it, simply uncomment the appropriate line in the Dockerfile.

NOTE: Per default, only previews for BMP, GIF, JPEG, MarkDown, MP3, PNG, TXT, and XBitmap Files are generated. The configuration of the preview generation can be done in config.php, as explained in the [Administration Manual](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html#previews)

NOTE: Nextcloud recommends [disabling preview generation](https://docs.nextcloud.com/server/latest/admin_manual/installation/harden_server.html#disable-preview-image-generation) for high security deployments, as preview generation opens your nextcloud instance to new possible attack vectors.

The required steps for each optional/recommended package that is not already in the Nextcloud image are listed here, so that the Dockerfile can easily be modified to only install the needed extra packages. Simply remove the steps for the unwanted packages from the Dockerfile.

#### PHP Module bz2
`docker-php-ext-install bz2`

#### PHP Module imap
`apt install libc-client-dev libkrb5-dev`
`docker-php-ext-configure imap --with-kerberos --with-imap-ssl`
`docker-php-ext-install imap`

#### PHP Module gmp
`apt install libgmp3-dev`
`docker-php-ext-install gmp`

#### PHP Module smbclient
`apt install smbclient libsmbclient-dev`
`pecl install smbclient`
`docker-php-ext-enable smbclient`

#### ffmpeg
`apt install ffmpeg`

#### imagemagick SVG support
`apt install libmagickcore-6.q16-6-extra`

#### LibreOffice
`apt install libreoffice`

#### CRON via supervisor
`apt install supervisor`
`mkdir /var/log/supervisord /var/run/supervisord`
The following Dockerfile commands are also necessary for a sucessfull cron installation:
`COPY supervisord.conf /etc/supervisor/supervisord.conf`
`CMD ["/usr/bin/supervisord"]`



## docker-compose
In `docker-compose` additional services are bundled to create a complete nextcloud installation. The examples are designed to run out-of-the-box.
Before running the examples you have to modify the `db.env` and `docker-compose.yml` file and fill in your custom information.

The docker-compose examples make heavily use of derived Dockerfiles to add configuration files into the containers. This way they should also work on remote docker systems as _Docker for Windows_. When running docker-compose on the same host as the docker daemon, another possibility would be to simply mount the files in the volumes section in the `docker-compose.yml` file.


### insecure
This example should only be used for testing on the local network because it uses a unencrypted http connection.
When you want to have your server reachable from the internet adding HTTPS-encryption is mandatory!
For this use one of the [with-nginx-proxy](#with-nginx-proxy) examples.

To use this example complete the following steps:

1. if you use mariadb or mysql choose a root password for the database in `docker-compose.yml` behind `MYSQL_ROOT_PASSWORD=`
2. choose a password for the database user nextcloud in `db.env` behind `MYSQL_PASSWORD=` (for mariadb/mysql) or `POSTGRES_PASSWORD=` (for postgres)
3. run `docker-compose build --pull` to pull the most recent base images and build the custom dockerfiles
4. start nextcloud with `docker-compose up -d`


If you want to update your installation to a newer version of nextcloud, repeat the steps 3 and 4.


### with-nginx-proxy
The nginx proxy adds a proxy layer between nextcloud and the internet. The proxy is designed to serve multiple sites on the same host machine.

The advantage in adding this layer is the ability to add a container for [Let's Encrypt](https://letsencrypt.org/) certificate handling.
This combination of the [nginxproxy/nginx-proxy](https://github.com/nginx-proxy/nginx-proxy) and [nginxproxy/acme-companion](https://github.com/nginx-proxy/acme-companion) containers creates a fully automated https encryption of the nextcloud installation without worrying about certificate generation, validation or renewal.

**This setup only works with a valid domain name on a server that is reachable from the internet.**

To use this example complete the following steps:

1. open `docker-compose.yml`
   1. insert your nextcloud domain behind `VIRTUAL_HOST=`and `LETSENCRYPT_HOST=`
   2. enter a valid email behind `LETSENCRYPT_EMAIL=`
   3. if you use mariadb or mysql choose a root password for the database behind `MYSQL_ROOT_PASSWORD=`
2. choose a password for the database user nextcloud in `db.env` behind `MYSQL_PASSWORD=` (for mariadb/mysql) or `POSTGRES_PASSWORD=` (for postgres)
3. run `docker-compose build --pull` to pull the most recent base images and build the custom dockerfiles
4. start nextcloud with `docker-compose up -d`


If you want to update your installation to a newer version of nextcloud, repeat the steps 3 and 4.
