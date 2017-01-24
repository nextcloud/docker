What is Nextcloud?

A safe home for all your data. Access & share your files, calendars, contacts, mail & more from any device, on your terms.

![logo](https://github.com/nextcloud/docker/raw/master/logo.png)

# How to use this image
This image is designed to be used in a micro-service environment. It consists of the Nextcloud installation in an [php-fpm](https://hub.docker.com/_/php/) container. To use this image it must be combined with any webserver that can proxy the http requests to the FastCGI-port of the container.

## Start Nextcloud

Starting Nextcloud php-fpm instance listening on port 9000 is as easy as the following:

```console
$ docker run -d indiehosters/nextcloud
```

Now you can get access to fpm running on port 9000 inside the container. If you want to access it from the internet, we recommend using a reverse proxy in front. You can install it directly on your machine or use an additional container (You can find more information on that on the docker-compose section). Once you have a reverse proxy, you can access Nextcloud at http://localhost/ and go through the wizard.

By default this container uses SQLite for data storage, but the Nextcloud setup wizard (appears on first run) allows connecting to an existing MySQL/MariaDB or PostgreSQL database. You can also link a database container, e.g. `--link my-mysql:mysql`, and then use `mysql` as the database host on setup.

## Persistent data

All data beyond that which lives in the database (file uploads, etc) is stored within several volumes, which are all separately controlled (to ensure that the source code of NextCloud can be updated by switching Docker versions -- please always follow the correct upgrade process despite the ease of just switching images):

- `-v /<mydatalocation>/apps:/var/www/html/apps` installed / modified apps
- `-v /<mydatalocation>/config:/var/www/html/config` local configuration
- `-v /<mydatalocation>/data:/var/www/html/data` the actual data of your Nextcloud

## ... via [`docker-compose`](https://github.com/docker/compose)

The recommended minimal setup is using this image in combination with two containers: A database container and a reverse proxy for the http connection to the service.
A working example can be found at [IndieHosters/Nextcloud](https://github.com/indiehosters/nextcloud).

If you want to access your Nextcloud from the internet we recommend configuring your reverse proxy to use encryption (for example via [let's Encrypt](https://letsencrypt.org/))

## Update to a newer version

To update your Nextcloud version you simply have to pull and start the new container.
```console
$ docker pull indiehosters/nextcloud
$ docker run -d indiehosters/nextcloud
```
When you access your site the update wizard will show up.
