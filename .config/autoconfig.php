<?php

$autoconfig_enabled = false;

if (getenv('SQLITE_DATABASE')) {
    $AUTOCONFIG['dbtype'] = 'sqlite';
    $AUTOCONFIG['dbname'] = getenv('SQLITE_DATABASE');
    $autoconfig_enabled = true;
} elseif (getenv('MYSQL_HOST')) {
    $AUTOCONFIG['dbtype'] = 'mysql';
    $AUTOCONFIG['dbname'] = getenv('MYSQL_DATABASE_FILE') ? trim(file_get_contents(getenv('MYSQL_DATABASE_FILE'))) : getenv('MYSQL_DATABASE');
    $AUTOCONFIG['dbuser'] = getenv('MYSQL_USER_FILE') ? trim(file_get_contents(getenv('MYSQL_USER_FILE'))) : getenv('MYSQL_USER');
    $AUTOCONFIG['dbpass'] = getenv('MYSQL_PASSWORD_FILE') ? trim(file_get_contents(getenv('MYSQL_PASSWORD_FILE'))) : getenv('MYSQL_PASSWORD');
    $AUTOCONFIG['dbhost'] = getenv('MYSQL_HOST');
    $autoconfig_enabled = $AUTOCONFIG['dbname'] && $AUTOCONFIG['dbuser'] && $AUTOCONFIG['dbpass'] && $AUTOCONFIG['dbhost'];
} elseif (getenv('POSTGRES_HOST')) {
    $AUTOCONFIG['dbtype'] = 'pgsql';
    $AUTOCONFIG['dbname'] = getenv('POSTGRES_DB_FILE') ? trim(file_get_contents(getenv('POSTGRES_DB_FILE'))) : getenv('POSTGRES_DB');
    $AUTOCONFIG['dbuser'] = getenv('POSTGRES_USER_FILE') ? trim(file_get_contents(getenv('POSTGRES_USER_FILE'))) : getenv('POSTGRES_USER');
    $AUTOCONFIG['dbpass'] = getenv('POSTGRES_PASSWORD_FILE') ? trim(file_get_contents(getenv('POSTGRES_PASSWORD_FILE'))) : getenv('POSTGRES_PASSWORD');
    $AUTOCONFIG['dbhost'] = getenv('POSTGRES_HOST');
    $autoconfig_enabled = $AUTOCONFIG['dbname'] && $AUTOCONFIG['dbuser'] && $AUTOCONFIG['dbpass'] && $AUTOCONFIG['dbhost'];
}

if ($autoconfig_enabled) {
    $AUTOCONFIG['directory'] = getenv('NEXTCLOUD_DATA_DIR') ?: '/var/www/html/data';
}
