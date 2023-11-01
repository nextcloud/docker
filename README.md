# What is Nextcloud?

[![GitHub CI build status badge](https://github.com/nextcloud/docker/workflows/Images/badge.svg)](https://github.com/nextcloud/docker/actions?query=workflow%3AImages)
[![update.sh build status badge](https://github.com/nextcloud/docker/workflows/update.sh/badge.svg)](https://github.com/nextcloud/docker/actions?query=workflow%3Aupdate.sh)
[![amd64 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/amd64/job/nextcloud.svg?label=amd64)](https://doi-janky.infosiftr.net/job/multiarch/job/amd64/job/nextcloud)
[![arm32v5 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/arm32v5/job/nextcloud.svg?label=arm32v5)](https://doi-janky.infosiftr.net/job/multiarch/job/arm32v5/job/nextcloud)
[![arm32v6 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/arm32v6/job/nextcloud.svg?label=arm32v6)](https://doi-janky.infosiftr.net/job/multiarch/job/arm32v6/job/nextcloud)
[![arm32v7 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/arm32v7/job/nextcloud.svg?label=arm32v7)](https://doi-janky.infosiftr.net/job/multiarch/job/arm32v7/job/nextcloud)
[![arm64v8 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/arm64v8/job/nextcloud.svg?label=arm64v8)](https://doi-janky.infosiftr.net/job/multiarch/job/arm64v8/job/nextcloud)
[![i386 build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/i386/job/nextcloud.svg?label=i386)](https://doi-janky.infosiftr.net/job/multiarch/job/i386/job/nextcloud)
[![mips64le build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/mips64le/job/nextcloud.svg?label=mips64le)](https://doi-janky.infosiftr.net/job/multiarch/job/mips64le/job/nextcloud)
[![ppc64le build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/ppc64le/job/nextcloud.svg?label=ppc64le)](https://doi-janky.infosiftr.net/job/multiarch/job/ppc64le/job/nextcloud)
[![s390x build status badge](https://img.shields.io/jenkins/s/https/doi-janky.infosiftr.net/job/multiarch/job/s390x/job/nextcloud.svg?label=s390x)](https://doi-janky.infosiftr.net/job/multiarch/job/s390x/job/nextcloud)

A safe home for all your data. Access & share your files, calendars, contacts, mail & more from any device, on your terms.

![logo_nextcloud_blue](https://github.com/nextcloud/docker/assets/28591861/2455cc67-f1d9-447e-8d8b-9784a50f8391)<svg xmlns="http://www.w3.org/2000/svg" xmlns:svg="http://www.w3.org/2000/svg" id="Layer_1" width="141.485" height="99.603" x="0" y="0" enable-background="new 0 0 196.6 72" version="1.1" viewBox="0 0 132.642 93.377" xml:space="preserve"><metadata id="metadata20"/><defs id="defs18"><clipPath id="clipPath8812" clipPathUnits="userSpaceOnUse"><circle id="circle8814" cx="95.669" cy="95.669" r="79.724" style="fill:#00080d;fill-opacity:1;stroke-width:1"/></clipPath></defs><path id="path1052" d="m 66.407896,9.375 c -11.805271,0 -21.811217,8.003196 -24.912392,18.846621 -2.695245,-5.751517 -8.535934,-9.780938 -15.263394,-9.780938 -9.25185,0 -16.85711,7.605263 -16.85711,16.857108 0,9.251833 7.60526,16.860567 16.85711,16.860567 6.72746,0 12.568149,-4.031885 15.263395,-9.784412 3.101175,10.84425 13.10712,18.850106 24.912391,18.850106 11.717964,0 21.67289,-7.885111 24.853382,-18.607048 2.745036,5.621934 8.513436,9.541354 15.145342,9.541354 9.25185,0 16.86057,-7.608734 16.86057,-16.860567 0,-9.251845 -7.60872,-16.857108 -16.86057,-16.857108 -6.631906,0 -12.400306,3.916965 -15.145342,9.537891 C 88.080786,17.257475 78.12586,9.375 66.407896,9.375 Z m 0,9.895518 c 8.911648,0 16.030748,7.115653 16.030748,16.027273 0,8.911605 -7.1191,16.030737 -16.030748,16.030737 -8.911593,0 -16.027247,-7.119132 -16.027247,-16.030737 0,-8.91162 7.115653,-16.027271 16.027247,-16.027273 z M 26.23211,28.336202 c 3.90438,0 6.96505,3.057188 6.96505,6.961589 0,3.904386 -3.06067,6.965049 -6.96505,6.965049 -3.90439,0 -6.96161,-3.060663 -6.96161,-6.965049 0,-3.904401 3.05722,-6.961589 6.96161,-6.961589 z m 80.17451,0 c 3.90442,0 6.96506,3.057188 6.96506,6.961589 0,3.904386 -3.06066,6.965049 -6.96506,6.965049 -3.90436,0 -6.961576,-3.060663 -6.961576,-6.965049 0,-3.904401 3.057226,-6.961589 6.961576,-6.961589 z" style="color:#000;font-style:normal;font-variant:normal;font-weight:400;font-stretch:normal;font-size:medium;line-height:normal;font-family:sans-serif;text-indent:0;text-align:start;text-decoration:none;text-decoration-line:none;text-decoration-style:solid;text-decoration-color:#000;letter-spacing:normal;word-spacing:normal;text-transform:none;writing-mode:lr-tb;direction:ltr;baseline-shift:baseline;text-anchor:start;white-space:normal;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000;solid-opacity:1;fill:#0082c9;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:5.56590033;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:10;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate"/><path style="fill:#0082c9;fill-opacity:1;stroke-width:.47038522" id="path1174" d="m 21.235693,69.043756 c -0.32926,0 -0.47147,0.187936 -0.47147,0.517242 V 83.20368 c 0,0.32927 0.14221,0.51495 0.47147,0.51495 h 0.37763 c 0.32927,0 0.51494,-0.18568 0.51494,-0.51495 V 71.874833 l 7.4473,11.557727 c 0.0324,0.0505 0.0677,0.0842 0.10299,0.12123 0.0106,0.0125 0.0179,0.0256 0.0298,0.0366 0.0317,0.0289 0.0665,0.044 0.10065,0.0618 0.019,0.01 0.0338,0.0247 0.055,0.032 0.0148,0.005 0.0304,0.002 0.0458,0.006 0.0525,0.0135 0.10618,0.0275 0.16936,0.0275 h 0.37534 c 0.32926,0 0.47146,-0.18567 0.47146,-0.51495 V 69.560768 c 0,-0.329305 -0.1422,-0.517241 -0.47146,-0.517241 h -0.37534 c -0.32929,0 -0.51724,0.187936 -0.51724,0.517241 V 80.89011 l -7.4473,-11.557716 c -0.0254,-0.03939 -0.0561,-0.06339 -0.0847,-0.0939 -0.086,-0.121611 -0.2222,-0.194545 -0.41654,-0.194545 z m 89.420157,0.187676 c -0.32926,0 -0.18767,0.187956 -0.18767,0.517241 v 4.657417 c 0,0.47037 0.0456,0.79872 0.0456,0.79872 h -0.0456 c 0,0 -0.89419,-2.06893 -3.38722,-2.06893 -2.72821,0 -4.65771,2.16372 -4.56357,5.36231 0,3.19862 1.74024,5.41041 4.51551,5.41041 2.68118,0 3.5749,-2.16508 3.5749,-2.16508 h 0.048 c 0,0 -0.0939,0.28283 -0.0939,0.65913 v 0.79874 c 0,0.32926 0.18796,0.47148 0.51726,0.47148 h 0.32955 c 0.32927,0 0.46917,-0.18798 0.46917,-0.51724 V 69.748673 c 0,-0.329285 -0.51754,-0.517241 -0.84681,-0.517241 z m -36.549859,0.0481 c -0.329276,0 -0.13961,0.187976 -0.13961,0.517241 V 81.32017 c 0,2.25783 1.503766,2.54039 2.350463,2.54039 0.376301,0 0.517217,-0.18796 0.517217,-0.51721 v -0.32958 c 0,-0.32926 -0.188212,-0.46918 -0.423394,-0.46918 -0.470405,-0.047 -1.080249,-0.18887 -1.080249,-1.50594 V 69.79677 c 0,-0.329266 -0.517531,-0.517241 -0.846807,-0.517241 z M 57.220266,70.50169 c -0.32927,0 -0.517238,0.187975 -0.517238,0.51724 v 2.44659 1.17638 5.31423 c 0,2.44599 1.365105,3.81064 3.622946,3.81064 0.42334,0 0.563011,-0.13993 0.563011,-0.46918 v -0.2838 c 0,-0.37629 -0.139671,-0.47024 -0.563011,-0.51724 -0.799652,-0.047 -2.258905,-0.32912 -2.258905,-2.72809 v -5.17464 h 2.117009 c 0.329268,0 0.517238,-0.1399 0.517238,-0.46918 v -0.1419 c 0,-0.32926 -0.18797,-0.51722 -0.517238,-0.51722 h -2.117009 v -2.44659 c 0,-0.329265 -0.139909,-0.51724 -0.469177,-0.51724 z m -18.734963,2.63427 c -2.82229,0 -5.08192,2.02359 -5.12888,5.41037 0,3.19859 2.35289,5.40809 5.41039,5.40809 1.646328,0 2.86852,-0.70495 3.432986,-1.12831 0.23526,-0.18814 0.283014,-0.42392 0.141896,-0.65912 l -0.141896,-0.23346 c -0.141115,-0.28223 -0.374612,-0.33005 -0.656846,-0.14188 -0.470383,0.37629 -1.413295,0.94064 -2.730371,0.94064 -2.116709,0 -3.951319,-1.50604 -3.998279,-4.14019 h 7.479331 c 0.282247,0 0.517238,-0.23501 0.517238,-0.51725 0,-2.9634 -1.550291,-4.93889 -4.325569,-4.93889 z m 29.223883,0 c -3.057482,0 -5.409203,2.25755 -5.456161,5.45614 0,3.1986 2.352896,5.41039 5.410387,5.41039 1.881541,0 3.151307,-0.89493 3.668718,-1.31828 0.235262,-0.2352 0.280729,-0.42265 0.139619,-0.7049 L 71.33213,81.79165 c -0.188136,-0.28225 -0.376902,-0.33005 -0.659131,-0.14191 -0.470383,0.42334 -1.457552,1.08255 -2.915751,1.08255 -2.257826,0 -4.046348,-1.69419 -4.046348,-4.14019 0,-2.49302 1.788522,-4.18596 4.046348,-4.18596 1.223008,0 2.115816,0.61137 2.58618,0.94065 0.282241,0.18807 0.516748,0.18838 0.704913,-0.0938 l 0.1419,-0.23572 c 0.235271,-0.28224 0.187125,-0.51677 -0.0481,-0.7049 -0.517422,-0.42337 -1.645515,-1.17638 -3.432986,-1.17638 z m 15.899301,0 c -3.010451,0 -5.456156,2.30482 -5.456156,5.36231 0,3.10451 2.445705,5.45615 5.456156,5.45615 3.010478,0 5.456168,-2.35164 5.456168,-5.45615 0,-3.05749 -2.44569,-5.36231 -5.456168,-5.36231 z m -30.429991,0.15793 c -0.11518,0.0184 -0.226037,0.0959 -0.331857,0.22197 l -1.904164,2.26805 -1.423546,1.69818 -2.158205,-2.57015 -1.169505,-1.39608 c -0.105876,-0.12611 -0.225795,-0.19525 -0.350163,-0.20597 -0.124354,-0.01 -0.253796,0.0361 -0.379919,0.14189 l -0.288371,0.24258 c -0.252223,0.21167 -0.23901,0.44583 -0.02745,0.69807 l 1.904166,2.26803 1.579172,1.88357 -2.311543,2.75326 c -0.0024,0.002 -0.0035,0.005 -0.0046,0.006 l -1.167215,1.38923 c -0.211653,0.25223 -0.188132,0.51842 0.06408,0.73009 l 0.288368,0.2403 c 0.252239,0.21164 0.481813,0.15841 0.693465,-0.0939 l 1.901876,-2.26806 1.425834,-1.69818 2.158204,2.57244 c 10e-4,0.002 0.0035,0.004 0.0046,0.005 l 1.164928,1.3915 c 0.211652,0.25223 0.477834,0.27337 0.730081,0.0617 l 0.288371,-0.2403 c 0.252237,-0.21165 0.239134,-0.44581 0.02746,-0.69805 l -1.904161,-2.27034 -1.579177,-1.88129 2.311546,-2.75554 c 0.0024,-0.002 0.0035,-0.004 0.0046,-0.006 l 1.167214,-1.38921 c 0.211651,-0.25224 0.188132,-0.51844 -0.06408,-0.73009 l -0.288371,-0.2403 c -0.126112,-0.10587 -0.246408,-0.14655 -0.361607,-0.12815 z m 38.662308,0.0779 c -0.32928,0 -0.47148,0.18796 -0.47148,0.51723 v 6.06722 c 0,2.6812 1.9757,3.99829 4.42169,3.99829 2.446,0 4.421696,-1.31709 4.421696,-3.99829 v -6.06723 c 0.047,-0.32926 -0.13991,-0.51723 -0.469176,-0.51723 h -0.37763 c -0.32927,0 -0.51724,0.18797 -0.51724,0.51723 v 5.69189 c 0,1.59931 -1.035,3.05766 -3.05765,3.05766 -1.9756,0 -3.05763,-1.45835 -3.05763,-3.05766 v -5.69189 c 0,-0.32926 -0.18797,-0.51723 -0.51726,-0.51723 z m -53.403561,0.94063 c 1.505226,0 2.82161,1.08155 2.915753,3.24531 h -6.490633 c 0.32927,-2.11674 1.83447,-3.24531 3.57488,-3.24531 z m 45.171244,0.0939 c 2.210809,0 3.998303,1.74023 3.998303,4.09214 0,2.44598 -1.787494,4.23401 -3.998303,4.23401 -2.210781,0 -3.999385,-1.83505 -4.046332,-4.23401 0,-2.30488 1.835551,-4.09214 4.046332,-4.09214 z m 23.566303,0 c 2.21082,0 3.29339,2.02346 3.29339,4.1402 0,2.9634 -1.60102,4.18595 -3.34144,4.18595 -1.92856,0 -3.24413,-1.6459 -3.29108,-4.18595 0,-2.63415 1.50465,-4.1402 3.33913,-4.1402 z"/></svg>

This Docker micro-service image is developed and maintained by the Nextcloud community. Nextcloud GmbH does not offer support for this Docker image. When you are looking to get professional support, you can become an [enterprise](https://nextcloud.com/enterprise/) customer or use [Nextcloud All-in-One docker image](https://github.com/nextcloud/all-in-one#nextcloud-all-in-one) - as the name suggests, Nextcloud All-in-One provides easy deployment and maintenance of Nextcloud Hub included in this one Nextcloud instance.

# How to use this image
This image is designed to be used in a micro-service environment. There are two versions of the image you can choose from.

The `apache` tag contains a full Nextcloud installation including an apache web server. It is designed to be easy to use and gets you running pretty fast. This is also the default for the `latest` tag and version tags that are not further specified.

The second option is a `fpm` container. It is based on the [php-fpm](https://hub.docker.com/_/php/) image and runs a fastCGI-Process that serves your Nextcloud page. To use this image it must be combined with any webserver that can proxy the http requests to the FastCGI-port of the container.

[![Try in PWD](https://github.com/play-with-docker/stacks/raw/cff22438cb4195ace27f9b15784bbb497047afa7/assets/images/button.png)](http://play-with-docker.com?stack=https://raw.githubusercontent.com/nextcloud/docker/8db861d67f257a3e9ac1790ea06d4e2a7a193a6c/stack.yml)

## Using the apache image
The apache image contains a webserver and exposes port 80. To start the container type:

```console
$ docker run -d -p 8080:80 nextcloud
```

Now you can access Nextcloud at http://localhost:8080/ from your host system.


## Using the fpm image
To use the fpm image, you need an additional web server, such as [nginx](https://docs.nextcloud.com/server/latest/admin_manual/installation/nginx.html), that can proxy http-request to the fpm-port of the container. For fpm connection this container exposes port 9000. In most cases, you might want to use another container or your host as proxy. If you use your host you can address your Nextcloud container directly on port 9000. If you use another container, make sure that you add them to the same docker network (via `docker run --network <NAME> ...` or a `docker-compose` file). In both cases you don't want to map the fpm port to your host.

```console
$ docker run -d nextcloud:fpm
```

As the fastCGI-Process is not capable of serving static files (style sheets, images, ...), the webserver needs access to these files. This can be achieved with the `volumes-from` option. You can find more information in the [docker-compose section](#running-this-image-with-docker-compose).

## Using an external database
By default, this container uses SQLite for data storage but the Nextcloud setup wizard (appears on first run) allows connecting to an existing MySQL/MariaDB or PostgreSQL database. You can also link a database container, e. g. `--link my-mysql:mysql`, and then use `mysql` as the database host on setup. More info is in the docker-compose section.

## Persistent data
The Nextcloud installation and all data beyond what lives in the database (file uploads, etc.) are stored in the [unnamed docker volume](https://docs.docker.com/engine/tutorials/dockervolumes/#adding-a-data-volume) volume `/var/www/html`. The docker daemon will store that data within the docker directory `/var/lib/docker/volumes/...`. That means your data is saved even if the container crashes, is stopped or deleted.

A named Docker volume or a mounted host directory should be used for upgrades and backups. To achieve this, you need one volume for your database container and one for Nextcloud.

Nextcloud:
- `/var/www/html/` folder where all Nextcloud data lives
```console
$ docker run -d \
-v nextcloud:/var/www/html \
nextcloud
```

Database:
- `/var/lib/mysql` MySQL / MariaDB Data
- `/var/lib/postgresql/data` PostgreSQL Data
```console
$ docker run -d \
-v db:/var/lib/mysql \
mariadb:10.6
```

If you want to get fine grained access to your individual files, you can mount additional volumes for data, config, your theme and custom apps. The `data`, `config` files are stored in respective subfolders inside `/var/www/html/`. The apps are split into core `apps` (which are shipped with Nextcloud and you don't need to take care of) and a `custom_apps` folder. If you use a custom theme it would go into the `themes` subfolder.

Overview of the folders that can be mounted as volumes:

- `/var/www/html` Main folder, needed for updating
- `/var/www/html/custom_apps` installed / modified apps
- `/var/www/html/config` local configuration
- `/var/www/html/data` the actual data of your Nextcloud
- `/var/www/html/themes/<YOUR_CUSTOM_THEME>` theming/branding

If you want to use named volumes for all of these, it would look like this:
```console
$ docker run -d \
-v nextcloud:/var/www/html \
-v apps:/var/www/html/custom_apps \
-v config:/var/www/html/config \
-v data:/var/www/html/data \
-v theme:/var/www/html/themes/<YOUR_CUSTOM_THEME> \
nextcloud
```
If mounting additional volumes, you should note that data inside the main folder (`/var/www/html`) may be removed during installation and upgrades, unless listed in [upgrade.exclude](https://github.com/nextcloud/docker/blob/master/upgrade.exclude). You should consider:
- Confirming that [upgrade.exclude](https://github.com/nextcloud/docker/blob/master/upgrade.exclude) contains the files and folders that should persist during installation and upgrades; or 
- Mounting storage volumes to locations outside of `/var/www/html`.


## Using the Nextcloud command-line interface
To use the [Nextcloud command-line interface](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/occ_command.html) (aka. `occ` command):
```console
$ docker exec --user www-data CONTAINER_ID php occ
```
or for docker-compose:
```console
$ docker-compose exec --user www-data app php occ
```

## Auto configuration via environment variables
The Nextcloud image supports auto configuration via environment variables. You can preconfigure everything that is asked on the install page on first run. To enable auto configuration, set your database connection via the following environment variables. You must specify all of the environment variables for a given database or the database environment variables defaults to SQLITE. ONLY use one database type!

__SQLite__:
- `SQLITE_DATABASE` Name of the database using sqlite

__MYSQL/MariaDB__:
- `MYSQL_DATABASE` Name of the database using mysql / mariadb.
- `MYSQL_USER` Username for the database using mysql / mariadb.
- `MYSQL_PASSWORD` Password for the database user using mysql / mariadb.
- `MYSQL_HOST` Hostname of the database server using mysql / mariadb.

__PostgreSQL__:
- `POSTGRES_DB` Name of the database using postgres.
- `POSTGRES_USER` Username for the database using postgres.
- `POSTGRES_PASSWORD` Password for the database user using postgres.
- `POSTGRES_HOST` Hostname of the database server using postgres.

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. See [Docker secrets](#docker-secrets) section below.

If you set any group of values (i.e. all of `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_HOST`), they will not be asked in the install page on first run. With a complete configuration by using all variables for your database type, you can additionally configure your Nextcloud instance by setting admin user and password (only works if you set both):

- `NEXTCLOUD_ADMIN_USER` Name of the Nextcloud admin user.
- `NEXTCLOUD_ADMIN_PASSWORD` Password for the Nextcloud admin user.

If you want, you can set the data directory, otherwise default value will be used.

- `NEXTCLOUD_DATA_DIR` (default: `/var/www/html/data`) Configures the data directory where nextcloud stores all files from the users.

One or more trusted domains can be set through environment variable, too. They will be added to the configuration after install.

- `NEXTCLOUD_TRUSTED_DOMAINS` (not set by default) Optional space-separated list of domains

The install and update script is only triggered when a default command is used (`apache-foreground` or `php-fpm`). If you use a custom command you have to enable the install / update with

- `NEXTCLOUD_UPDATE` (default: `0`)

You might want to make sure the htaccess is up to date after each container update. Especially on multiple swarm nodes as any discrepancy will make your server unusable.

- `NEXTCLOUD_INIT_HTACCESS` (not set by default) Set it to true to enable run `occ maintenance:update:htaccess` after container initialization.

If you want to use Redis you have to create a separate [Redis](https://hub.docker.com/_/redis/) container in your setup / in your docker-compose file. To inform Nextcloud about the Redis container, pass in the following parameters:

- `REDIS_HOST` (not set by default) Name of Redis container
- `REDIS_HOST_PORT` (default: `6379`) Optional port for Redis, only use for external Redis servers that run on non-standard ports.
- `REDIS_HOST_PASSWORD` (not set by default) Redis password

The use of Redis is recommended to prevent file locking problems. See the examples for further instructions.

To use an external SMTP server, you have to provide the connection details. To configure Nextcloud to use SMTP add:

- `SMTP_HOST` (not set by default): The hostname of the SMTP server.
- `SMTP_SECURE` (empty by default): Set to `ssl` to use SSL, or `tls` to use STARTTLS.
- `SMTP_PORT` (default: `465` for SSL and `25` for non-secure connections): Optional port for the SMTP connection. Use `587` for an alternative port for STARTTLS.
- `SMTP_AUTHTYPE` (default: `LOGIN`): The method used for authentication. Use `PLAIN` if no authentication is required.
- `SMTP_NAME` (empty by default): The username for the authentication.
- `SMTP_PASSWORD` (empty by default): The password for the authentication.
- `MAIL_FROM_ADDRESS` (not set by default): Set the local-part for the 'from' field in the emails sent by Nextcloud.
- `MAIL_DOMAIN` (not set by default): Set a different domain for the emails than the domain where Nextcloud is installed.

Check the [Nextcloud documentation](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/email_configuration.html) for other values to configure SMTP.

To use an external S3 compatible object store as primary storage, set the following variables:
- `OBJECTSTORE_S3_HOST`: The hostname of the object storage server
- `OBJECTSTORE_S3_BUCKET`: The name of the bucket that Nextcloud should store the data in
- `OBJECTSTORE_S3_KEY`: AWS style access key
- `OBJECTSTORE_S3_SECRET`: AWS style secret access key
- `OBJECTSTORE_S3_PORT`: The port that the object storage server is being served over
- `OBJECTSTORE_S3_SSL` (default: `true`): Whether or not SSL/TLS should be used to communicate with object storage server
- `OBJECTSTORE_S3_REGION`: The region that the S3 bucket resides in.
- `OBJECTSTORE_S3_USEPATH_STYLE` (default: `false`): Not required for AWS S3
- `OBJECTSTORE_S3_LEGACYAUTH` (default: `false`): Not required for AWS S3
- `OBJECTSTORE_S3_OBJECT_PREFIX` (default: `urn:oid:`): Prefix to prepend to the fileid
- `OBJECTSTORE_S3_AUTOCREATE` (default: `true`): Create the container if it does not exist

Check the [Nextcloud documentation](https://docs.nextcloud.com/server/latest/admin_manual/configuration_files/primary_storage.html#simple-storage-service-s3) for more information.

To use an external OpenStack Swift object store as primary storage, set the following variables:
- `OBJECTSTORE_SWIFT_URL`: The Swift identity (Keystone) endpoint
- `OBJECTSTORE_SWIFT_AUTOCREATE` (default: `false`): Whether or not Nextcloud should automatically create the Swift container
- `OBJECTSTORE_SWIFT_USER_NAME`: Swift username
- `OBJECTSTORE_SWIFT_USER_PASSWORD`: Swift user password
- `OBJECTSTORE_SWIFT_USER_DOMAIN` (default: `Default`): Swift user domain
- `OBJECTSTORE_SWIFT_PROJECT_NAME`: OpenStack project name
- `OBJECTSTORE_SWIFT_PROJECT_DOMAIN` (default: `Default`): OpenStack project domain
- `OBJECTSTORE_SWIFT_SERVICE_NAME` (default: `swift`): Swift service name
- `OBJECTSTORE_SWIFT_REGION`: Swift endpoint region
- `OBJECTSTORE_SWIFT_CONTAINER_NAME`: Swift container (bucket) that Nextcloud should store the data in

Check the [Nextcloud documentation](https://docs.nextcloud.com/server/latest/admin_manual/configuration_files/primary_storage.html#openstack-swift) for more information.

To customize other PHP limits you can simply change the following variables:
- `PHP_MEMORY_LIMIT` (default `512M`) This sets the maximum amount of memory in bytes that a script is allowed to allocate. This is meant to help prevent poorly written scripts from eating up all available memory but it can prevent normal operation if set too tight.
- `PHP_UPLOAD_LIMIT` (default `512M`) This sets the upload limit (`post_max_size` and `upload_max_filesize`) for big files. Note that you may have to change other limits depending on your client, webserver or operating system. Check the [Nextcloud documentation](https://docs.nextcloud.com/server/latest/admin_manual/configuration_files/big_file_upload_configuration.html) for more information.

To customize Apache max file upload limit you can change the following variable:
- `APACHE_BODY_LIMIT` (default `1073741824` [1GiB]) This restricts the total 
size of the HTTP request body sent from the client. It specifies the number of _bytes_ that are allowed in a request body. A value of **0** means **unlimited**. Check the [Nextcloud documentation](https://docs.nextcloud.com/server/latest/admin_manual/configuration_files/big_file_upload_configuration.html#apache) for more information.


## Auto configuration via hook folders

There are 5 hooks

- `pre-installation` Executed before the Nextcloud is installed/initiated
- `post-installation` Executed after the Nextcloud is installed/initiated
- `pre-upgrade` Executed before the Nextcloud is upgraded
- `post-upgrade` Executed after the Nextcloud is upgraded
- `before-starting` Executed before the Nextcloud starts

To use the hooks triggered by the `entrypoint` script, either
- Added your script(s) to the individual of the hook folder(s), which are located at the path `/docker-entrypoint-hooks.d` in the container
- Use volume(s) if you want to use script from the host system inside the container, see example.

**Note:** Only the script(s) located in a hook folder (not sub-folders), ending with `.sh` and marked as executable, will be executed.

**Example:** Mount using volumes
```yaml
...
  app:
    image: nextcloud:stable

    volumes:
      - ./app-hooks/pre-installation:/docker-entrypoint-hooks.d/pre-installation
      - ./app-hooks/post-installation:/docker-entrypoint-hooks.d/post-installation
      - ./app-hooks/pre-upgrade:/docker-entrypoint-hooks.d/pre-upgrade
      - ./app-hooks/post-upgrade:/docker-entrypoint-hooks.d/post-upgrade
      - ./app-hooks/before-starting:/docker-entrypoint-hooks.d/before-starting
...
```


## Using the apache image behind a reverse proxy and auto configure server host and protocol

The apache image will replace the remote addr (IP address visible to Nextcloud) with the IP address from `X-Real-IP` if the request is coming from a proxy in `10.0.0.0/8`, `172.16.0.0/12` or `192.168.0.0/16` by default. If you want Nextcloud to pick up the server host (`HTTP_X_FORWARDED_HOST`), protocol (`HTTP_X_FORWARDED_PROTO`) and client IP (`HTTP_X_FORWARDED_FOR`) from a trusted proxy, then disable rewrite IP and add the reverse proxy's IP address to `TRUSTED_PROXIES`.

- `APACHE_DISABLE_REWRITE_IP` (not set by default): Set to 1 to disable rewrite IP.

- `TRUSTED_PROXIES` (empty by default): A space-separated list of trusted proxies. CIDR notation is supported for IPv4.

If the `TRUSTED_PROXIES` approach does not work for you, try using fixed values for overwrite parameters.

- `OVERWRITEHOST` (empty by default): Set the hostname of the proxy. Can also specify a port.
- `OVERWRITEPROTOCOL` (empty by default): Set the protocol of the proxy, http or https.
- `OVERWRITECLIURL` (empty by default): Set the cli url of the proxy (e.g. https://mydnsname.example.com)
- `OVERWRITEWEBROOT` (empty by default): Set the absolute path of the proxy.
- `OVERWRITECONDADDR` (empty by default): Regex to overwrite the values dependent on the remote address.

Check the [Nexcloud documentation](https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/reverse_proxy_configuration.html) for more details.

Keep in mind that once set, removing these environment variables won't remove these values from the configuration file, due to how Nextcloud merges configuration files together.

# Running this image with docker-compose
The easiest way to get a fully featured and functional setup is using a `docker-compose` file. There are too many different possibilities to setup your system, so here are only some examples of what you have to look for.

At first, make sure you have chosen the right base image (fpm or apache) and added features you wanted (see below). In every case, you would want to add a database container and docker volumes to get easy access to your persistent data. When you want to have your server reachable from the internet, adding HTTPS-encryption is mandatory! See below for more information.

## Base version - apache
This version will use the apache image and add a mariaDB container. The volumes are set to keep your data persistent. This setup provides **no ssl encryption** and is intended to run behind a proxy.

Make sure to pass in values for `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD` variables before you run this setup.

```yaml
version: '2'

volumes:
  nextcloud:
  db:

services:
  db:
    image: mariadb:10.6
    restart: always
    command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=
      - MYSQL_PASSWORD=
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud

  app:
    image: nextcloud
    restart: always
    ports:
      - 8080:80
    links:
      - db
    volumes:
      - nextcloud:/var/www/html
    environment:
      - MYSQL_PASSWORD=
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_HOST=db

```

Then run `docker-compose up -d`, now you can access Nextcloud at http://localhost:8080/ from your host system.

## Base version - FPM
When using the FPM image, you need another container that acts as web server on port 80 and proxies the requests to the Nextcloud container. In this example a simple nginx container is combined with the Nextcloud-fpm image and a MariaDB database container. The data is stored in docker volumes. The nginx container also needs access to static files from your Nextcloud installation. It gets access to all the volumes mounted to Nextcloud via the `volumes_from` option.The configuration for nginx is stored in the configuration file `nginx.conf`, that is mounted into the container. An example can be found in the examples section [here](https://github.com/nextcloud/docker/tree/master/.examples).

As this setup does **not include encryption**, it should be run behind a proxy.

Make sure to pass in values for `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD` variables before you run this setup.

```yaml
version: '2'

volumes:
  nextcloud:
  db:

services:
  db:
    image: mariadb:10.6
    restart: always
    command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
    volumes:
      - db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=
      - MYSQL_PASSWORD=
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud

  app:
    image: nextcloud:fpm
    restart: always
    links:
      - db
    volumes:
      - nextcloud:/var/www/html
    environment:
      - MYSQL_PASSWORD=
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_HOST=db

  web:
    image: nginx
    restart: always
    ports:
      - 8080:80
    links:
      - app
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    volumes_from:
      - app
```

Then run `docker-compose up -d`, now you can access Nextcloud at http://localhost:8080/ from your host system.

# Docker Secrets
As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. For example:
```yaml
version: '3.2'

services:
  db:
    image: postgres
    restart: always
    volumes:
      - db:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB_FILE=/run/secrets/postgres_db
      - POSTGRES_USER_FILE=/run/secrets/postgres_user
      - POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password
    secrets:
      - postgres_db
      - postgres_password
      - postgres_user

  app:
    image: nextcloud
    restart: always
    ports:
      - 8080:80
    volumes:
      - nextcloud:/var/www/html
    environment:
      - POSTGRES_HOST=db
      - POSTGRES_DB_FILE=/run/secrets/postgres_db
      - POSTGRES_USER_FILE=/run/secrets/postgres_user
      - POSTGRES_PASSWORD_FILE=/run/secrets/postgres_password
      - NEXTCLOUD_ADMIN_PASSWORD_FILE=/run/secrets/nextcloud_admin_password
      - NEXTCLOUD_ADMIN_USER_FILE=/run/secrets/nextcloud_admin_user
    depends_on:
      - db
    secrets:
      - nextcloud_admin_password
      - nextcloud_admin_user
      - postgres_db
      - postgres_password
      - postgres_user

volumes:
  db:
  nextcloud:

secrets:
  nextcloud_admin_password:
    file: ./nextcloud_admin_password.txt # put admin password in this file
  nextcloud_admin_user:
    file: ./nextcloud_admin_user.txt # put admin username in this file
  postgres_db:
    file: ./postgres_db.txt # put postgresql db name in this file
  postgres_password:
    file: ./postgres_password.txt # put postgresql password in this file
  postgres_user:
    file: ./postgres_user.txt # put postgresql username in this file
```

Currently, this is only supported for `NEXTCLOUD_ADMIN_PASSWORD`, `NEXTCLOUD_ADMIN_USER`, `MYSQL_DATABASE`, `MYSQL_PASSWORD`, `MYSQL_USER`, `POSTGRES_DB`, `POSTGRES_PASSWORD`, `POSTGRES_USER`, `REDIS_HOST_PASSWORD`, `SMTP_PASSWORD`, `OBJECTSTORE_S3_KEY`, and `OBJECTSTORE_S3_SECRET`.

If you set any group of values (i.e. all of `MYSQL_DATABASE_FILE`, `MYSQL_USER_FILE`, `MYSQL_PASSWORD_FILE`, `MYSQL_HOST`), the script will not use the corresponding group of environment variables (`MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_HOST`).

# Make your Nextcloud available from the internet
Until here, your Nextcloud is just available from your docker host. If you want your Nextcloud available from the internet adding SSL encryption is mandatory.

## HTTPS - SSL encryption
There are many different possibilities to introduce encryption depending on your setup.

We recommend using a reverse proxy in front of your Nextcloud installation. Your Nextcloud will only be reachable through the proxy, which encrypts all traffic to the clients. You can mount your manually generated certificates to the proxy or use a fully automated solution which generates and renews the certificates for you.

In our [examples](https://github.com/nextcloud/docker/tree/master/.examples) section we have an example for a fully automated setup using a reverse proxy, a container for [Let's Encrypt](https://letsencrypt.org/) certificate handling, database and Nextcloud. It uses the popular [nginx-proxy](https://github.com/jwilder/nginx-proxy) and [docker-letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion) containers. Please check the according documentations before using this setup.

# First use
When you first access your Nextcloud, the setup wizard will appear and ask you to choose an administrator account username, password and the database connection. For the database use `db` as host and `nextcloud` as table and user name. Also enter the password you chose in your `docker-compose.yml` file.

# Update to a newer version
Updating the Nextcloud container is done by pulling the new image, throwing away the old container and starting the new one.

**It is only possible to upgrade one major version at a time. For example, if you want to upgrade from version 14 to 16, you will have to upgrade from version 14 to 15, then from 15 to 16.**

Since all data is stored in volumes, nothing gets lost. The startup script will check for the version in your volume and the installed docker version. If it finds a mismatch, it automatically starts the upgrade process. Don't forget to add all the volumes to your new container, so it works as expected.

```console
$ docker pull nextcloud
$ docker stop <your_nextcloud_container>
$ docker rm <your_nextcloud_container>
$ docker run <OPTIONS> -d nextcloud
```
Beware that you have to run the same command with the options that you used to initially start your Nextcloud. That includes  volumes, port mapping.

When using docker-compose your compose file takes care of your configuration, so you just have to run:

```console
$ docker-compose pull
$ docker-compose up -d
```


# Adding Features
A lot of people want to use additional functionality inside their Nextcloud installation. If the image does not include the packages you need, you can easily build your own image on top of it. Start your derived image with the `FROM` statement and add whatever you like.

```dockerfile
FROM nextcloud:apache

RUN ...

```
The [examples folder](https://github.com/nextcloud/docker/blob/master/.examples) gives a few examples on how to add certain functionalities, like including the cron job, smb-support or imap-authentication.

If you use your own Dockerfile, you need to configure your docker-compose file accordingly. Switch out the `image` option with `build`. You have to specify the path to your Dockerfile. (in the example it's in the same directory next to the docker-compose file)

```yaml
  app:
    build: .
    restart: always
    links:
      - db
    volumes:
      - data:/var/www/html/data
      - config:/var/www/html/config
      - apps:/var/www/html/apps
```

If you intend to use another command to run the image, make sure that you set `NEXTCLOUD_UPDATE=1` in your Dockerfile. Otherwise the installation and update will not work.

```dockerfile
FROM nextcloud:apache

...

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord"]
```


**Updating** your own derived image is also very simple. When a new version of the Nextcloud image is available run:

```console
docker build -t your-name --pull .
docker run -d your-name
```

or for docker-compose:
```console
docker-compose build --pull
docker-compose up -d
```

The `--pull` option tells docker to look for new versions of the base image. Then the build instructions inside your `Dockerfile` are run on top of the new image.

# Migrating an existing installation
You're already using Nextcloud and want to switch to docker? Great! Here are some things to look out for:

1. Define your whole Nextcloud infrastructure in a `docker-compose` file and run it with `docker-compose up -d` to get the base installation, volumes and database. Work from there.
2. Restore your database from a mysqldump (nextcloud\_db\_1 is the name of your db container)
    - To import from a MySQL dump use the following commands
    ```console
    docker cp ./database.dmp nextcloud_db_1:/dmp
    docker-compose exec db sh -c "mysql --user USER --password PASSWORD nextcloud < /dmp"
    docker-compose exec db rm /dmp
    ```
    - To import from a PostgreSQL dump use to following commands
    ```console
    docker cp ./database.dmp nextcloud_db_1:/dmp
    docker-compose exec db sh -c "psql -U USER --set ON_ERROR_STOP=on nextcloud < /dmp"
    docker-compose exec db rm /dmp
    ```
3. Edit your config.php
    1. Set database connection
        - In case of MySQL database
        ```php
        'dbhost' => 'db:3306',
        ```
        - In case of PostgreSQL database
        ```php
        'dbhost' => 'db:5432',
        ```
    2. Make sure you have no configuration for the `apps_paths`. Delete lines like these
        ```php
        'apps_paths' => array (
            0 => array (
                'path' => OC::$SERVERROOT.'/apps',
                'url' => '/apps',
                'writable' => true,
            ),
        ),
        ```
    3. Make sure to have the `apps` directory non writable and the `custom_apps` directory writable
        ```php
        'apps_paths' => array (
          0 => array (
            'path' => '/var/www/html/apps',
            'url' => '/apps',
            'writable' => false,
          ),
          1 => array (
            'path' => '/var/www/html/custom_apps',
            'url' => '/custom_apps',
            'writable' => true,
          ),
        ),
        ```
    4. Make sure your data directory is set to /var/www/html/data
        ```php
        'datadirectory' => '/var/www/html/data',
        ```
4. Copy your data (nextcloud_app_1 is the name of your Nextcloud container):
    ```console
    docker cp ./data/ nextcloud_app_1:/var/www/html/
    docker-compose exec app chown -R www-data:www-data /var/www/html/data
    docker cp ./theming/ nextcloud_app_1:/var/www/html/
    docker-compose exec app chown -R www-data:www-data /var/www/html/theming
    docker cp ./config/config.php nextcloud_app_1:/var/www/html/config
    docker-compose exec app chown -R www-data:www-data /var/www/html/config
    ```
    If you want to preserve the metadata of your files like timestamps, copy the data directly on the host to the named volume using plain `cp` like this:
    ```console
    cp --preserve --recursive ./data/ /path/to/nextcloudVolume/data
    ```
5. Copy only the custom apps you use (or simply redownload them from the web interface):
    ```console
    docker cp ./custom_apps/ nextcloud_data:/var/www/html/
    docker-compose exec app chown -R www-data:www-data /var/www/html/custom_apps
    ```

# Questions / Issues
If you got any questions or problems using the image, please visit our [Github Repository](https://github.com/nextcloud/docker) and write an issue.
