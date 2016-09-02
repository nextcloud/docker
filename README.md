What is Nextcloud?

A safe home for all your data. Access & share your files, calendars, contacts, mail & more from any device, on your terms.

![logo](https://github.com/nextcloud/docker/blob/master/logo.png)

# How to use this image

## Start Nextcloud

Starting Nextcloud php-fpm instance listening on port 9000 is as easy as the following:

```console
$ docker run -d nextcloud
```

Now you can get access to fpm running on port 9000 inside the container. If you want to access it from the Internets, we recommend using a reverse proxy in front. You can find more information on that on the docker-compose section. Once you have a reverse proxy, go to http://localhost/ and go through the wizard. By default this container uses SQLite for data storage, but the wizard should allow for connecting to an existing database.

For a MySQL database you can link an database container, e.g. `--link my-mysql:mysql`, and then use `mysql` as the database host on setup.

## Persistent data

All data beyond what lives in the database (file uploads, etc) is stored within the default volume `/var/www/html`. With this volume, Nextcloud will only be updated when the file `version.php` is not present.

- `-v /<mydatalocation>:/var/www/html`

For fine grained data persistence, you can use 3 volumes, as shown below.

- `-v /<mydatalocation>/apps:/var/www/html/apps` installed / modified apps
- `-v /<mydatalocation>/config:/var/www/html/config` local configuration
- `-v /<mydatalocation>/data:/var/www/html/data` the actual data of your Nextcloud

## ... via [`docker-compose`](https://github.com/docker/compose)

You can use a setup that is used in production at [IndieHosters/Nextcloud](https://github.com/indiehosters/nextcloud).
