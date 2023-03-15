<?php

require_once "util.php";

$autoconfig_enabled = false;

if (getenv('SQLITE_DATABASE')) {
    $AUTOCONFIG['dbtype'] = 'sqlite';
    $AUTOCONFIG['dbname'] = getenv('SQLITE_DATABASE');
    $autoconfig_enabled = true;
} elseif (getFileEnv('MYSQL_DATABASE') && getFileEnv('MYSQL_USER') && getFileEnv('MYSQL_PASSWORD') && getenv('MYSQL_HOST')) {
    $AUTOCONFIG['dbtype'] = 'mysql';
    $AUTOCONFIG['dbname'] = getFileEnv('MYSQL_DATABASE');
    $AUTOCONFIG['dbuser'] = getFileEnv('MYSQL_USER');
    $AUTOCONFIG['dbpass'] = getFileEnv('MYSQL_PASSWORD');
    $AUTOCONFIG['dbhost'] = getenv('MYSQL_HOST');
    $autoconfig_enabled = true;
} elseif (getFileEnv('POSTGRES_DB') && getFileEnv('POSTGRES_USER') && getFileEnv('POSTGRES_PASSWORD') && getenv('POSTGRES_HOST')) {
    $AUTOCONFIG['dbtype'] = 'pgsql';
    $AUTOCONFIG['dbname'] = getFileEnv('POSTGRES_DB');
    $AUTOCONFIG['dbuser'] = getFileEnv('POSTGRES_USER');
    $AUTOCONFIG['dbpass'] = getFileEnv('POSTGRES_PASSWORD');
    $AUTOCONFIG['dbhost'] = getenv('POSTGRES_HOST');
    $autoconfig_enabled = true;
}

if ($autoconfig_enabled) {
    $AUTOCONFIG['directory'] = getenv('NEXTCLOUD_DATA_DIR') ?: '/var/www/html/data';
}
