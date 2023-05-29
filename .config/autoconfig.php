<?php

$autoconfig_enabled = false;

if (getenv('SQLITE_DATABASE')) {
    $AUTOCONFIG['dbtype'] = 'sqlite';
    $AUTOCONFIG['dbname'] = getenv('SQLITE_DATABASE');
    $autoconfig_enabled = true;
} else if ((getenv('MYSQL_DATABASE_FILE') || getenv('MYSQL_DATABASE')) &&
           (getenv('MYSQL_USER_FILE') || getenv('MYSQL_USER')) &&
           (getenv('MYSQL_PASSWORD_FILE') || getenv('MYSQL_PASSWORD')) &&
            getenv('MYSQL_HOST')) {
    $AUTOCONFIG['dbtype'] = 'mysql';

    if (getenv('MYSQL_DATABASE_FILE'))
        $AUTOCONFIG['dbname'] = trim(file_get_contents(getenv('MYSQL_DATABASE_FILE')));
    elseif (getenv('MYSQL_DATABASE'))
        $AUTOCONFIG['dbname'] = getenv('MYSQL_DATABASE');

    if (getenv('MYSQL_USER_FILE'))
        $AUTOCONFIG['dbuser'] = trim(file_get_contents(getenv('MYSQL_USER_FILE')));
    elseif (getenv('MYSQL_USER'))
        $AUTOCONFIG['dbuser'] = getenv('MYSQL_USER');

    if (getenv('MYSQL_PASSWORD_FILE'))
        $AUTOCONFIG['dbpass'] = trim(file_get_contents(getenv('MYSQL_PASSWORD_FILE')));
    elseif (getenv('MYSQL_PASSWORD'))
        $AUTOCONFIG['dbpass'] = getenv('MYSQL_PASSWORD');

    $AUTOCONFIG['dbhost'] = getenv('MYSQL_HOST');
    $autoconfig_enabled = true;
} elseif ((getenv('POSTGRES_DB_FILE') || getenv('POSTGRES_DB')) &&
          (getenv('POSTGRES_USER_FILE') || getenv('POSTGRES_USER')) &&
          (getenv('POSTGRES_PASSWORD_FILE') || getenv('POSTGRES_PASSWORD')) &&
           getenv('POSTGRES_HOST')) {
    $AUTOCONFIG['dbtype'] = 'pgsql';

    if (getenv('POSTGRES_DB_FILE'))
        $AUTOCONFIG['dbname'] = trim(file_get_contents(getenv('POSTGRES_DB_FILE')));
    elseif (getenv('POSTGRES_DB'))
        $AUTOCONFIG['dbname'] = getenv('POSTGRES_DB');

    if (getenv('POSTGRES_USER_FILE'))
        trim(file_get_contents(getenv('POSTGRES_USER_FILE')));
    elseif (getenv('POSTGRES_USER'))
        $AUTOCONFIG['dbuser'] = getenv('POSTGRES_USER');

    if (getenv('POSTGRES_PASSWORD_FILE'))
        $AUTOCONFIG['dbpass'] = trim(file_get_contents(getenv('POSTGRES_PASSWORD_FILE')));
    elseif (getenv('POSTGRES_PASSWORD'))
        $AUTOCONFIG['dbpass'] = getenv('POSTGRES_PASSWORD');

    $AUTOCONFIG['dbhost'] = getenv('POSTGRES_HOST');
    $autoconfig_enabled = true;
}

if ($autoconfig_enabled) {
    $AUTOCONFIG['directory'] = getenv('NEXTCLOUD_DATA_DIR') ?: '/var/www/html/data';
}
