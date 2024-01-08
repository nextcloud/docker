<?php

$autoconfig_enabled = false;

if (getenv('SQLITE_DATABASE')) {
    $AUTOCONFIG['dbtype'] = 'sqlite';
    $AUTOCONFIG['dbname'] = getenv('SQLITE_DATABASE');
    $autoconfig_enabled = true;
} elseif (getenv('MYSQL_HOST') && (getenv('MYSQL_DATABASE') || getenv('MYSQL_DATABASE_FILE')) && (getenv('MYSQL_USER') || getenv('MYSQL_USER_FILE')) && (getenv('MYSQL_PASSWORD') || getenv('MYSQL_PASSWORD_FILE'))) {
    $autoconfig_enabled = true;
    $AUTOCONFIG['dbtype'] = 'mysql';
    $AUTOCONFIG['dbhost'] = getenv('MYSQL_HOST');

    if (getenv('MYSQL_USER_FILE') && file_exists(getenv('MYSQL_USER_FILE'))) {
        $AUTOCONFIG['dbname'] = trim(file_get_contents(getenv('MYSQL_USER_FILE')));
    } elseif (getenv('MYSQL_DATABASE')) {
        $AUTOCONFIG['dbname'] = getenv('MYSQL_DATABASE');
    } else {
        $autoconfig_enabled = false;
    }

    if (getenv('POSTGRES_USER_FILE') && file_exists(getenv('POSTGRES_USER_FILE'))) {
        $AUTOCONFIG['dbuser'] = trim(file_get_contents(getenv('POSTGRES_USER_FILE')));
    } elseif (getenv('MYSQL_USER')) {
        $AUTOCONFIG['dbuser'] = getenv('MYSQL_USER');
    } else {
        $autoconfig_enabled = false;
    }

    if (getenv('MYSQL_PASSWORD_FILE') && file_exists(getenv('MYSQL_PASSWORD_FILE'))) {
        $AUTOCONFIG['dbpass'] = trim(file_get_contents(getenv('MYSQL_PASSWORD_FILE')));
    } elseif (getenv('MYSQL_PASSWORD')) {
        $AUTOCONFIG['dbpass'] = getenv('MYSQL_PASSWORD');
    } else {
        $autoconfig_enabled = false;
    }
} elseif (getenv('POSTGRES_HOST') && (getenv('POSTGRES_DB') || getenv('POSTGRES_DB_FILE')) && (getenv('POSTGRES_USER') || getenv('POSTGRES_USER_FILE')) && (getenv('POSTGRES_PASSWORD') || getenv('POSTGRES_PASSWORD_FILE'))) {
    $autoconfig_enabled = true;
    $AUTOCONFIG['dbtype'] = 'pgsql';
    $AUTOCONFIG['dbhost'] = getenv('POSTGRES_HOST');

    if (getenv('POSTGRES_DB_FILE') && file_exists(getenv('POSTGRES_DB_FILE'))) {
        $AUTOCONFIG['dbname'] = trim(file_get_contents(getenv('POSTGRES_DB_FILE')));
    } elseif (getenv('POSTGRES_DB')) {
        $AUTOCONFIG['dbname'] = getenv('POSTGRES_DB');
    } else {
        $autoconfig_enabled = false;
    }

    if (getenv('POSTGRES_USER_FILE') && file_exists(getenv('POSTGRES_USER_FILE'))) {
        $AUTOCONFIG['dbuser'] = trim(file_get_contents(getenv('POSTGRES_USER_FILE')));
    } elseif (getenv('POSTGRES_USER')) {
        $AUTOCONFIG['dbuser'] = getenv('POSTGRES_USER');
    } else {
        $autoconfig_enabled = false;
    }

    if (getenv('POSTGRES_PASSWORD_FILE') && file_exists(getenv('POSTGRES_PASSWORD_FILE'))) {
        $AUTOCONFIG['dbpass'] = trim(file_get_contents(getenv('POSTGRES_PASSWORD_FILE')));
    } elseif (getenv('POSTGRES_PASSWORD')) {
        $AUTOCONFIG['dbpass'] = getenv('POSTGRES_PASSWORD');
    } else {
        $autoconfig_enabled = false;
    }
}

if ($autoconfig_enabled) {
    $AUTOCONFIG['directory'] = getenv('NEXTCLOUD_DATA_DIR') ?: '/var/www/html/data';
}
