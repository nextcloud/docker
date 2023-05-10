<?php

$autoconfig_enabled = false;

if (getenv('SQLITE_DATABASE')) {
    $CONFIG['dbtype'] = 'sqlite';
    $CONFIG['dbname'] = getenv('SQLITE_DATABASE');
    $autoconfig_enabled = true;
} elseif (getenv('MYSQL_DATABASE_FILE') && getenv('MYSQL_USER_FILE') && getenv('MYSQL_PASSWORD_FILE') && getenv('MYSQL_HOST')) {
    $CONFIG['dbtype'] = 'mysql';
    $CONFIG['dbname'] = trim(file_get_contents(getenv('MYSQL_DATABASE_FILE')));
    $CONFIG['dbuser'] = trim(file_get_contents(getenv('MYSQL_USER_FILE')));
    $CONFIG['dbpassword'] = trim(file_get_contents(getenv('MYSQL_PASSWORD_FILE')));
    $CONFIG['dbhost'] = getenv('MYSQL_HOST');
    $autoconfig_enabled = true;
} elseif (getenv('MYSQL_DATABASE') && getenv('MYSQL_USER') && getenv('MYSQL_PASSWORD') && getenv('MYSQL_HOST')) {
    $CONFIG['dbtype'] = 'mysql';
    $CONFIG['dbname'] = getenv('MYSQL_DATABASE');
    $CONFIG['dbuser'] = getenv('MYSQL_USER');
    $CONFIG['dbpassword'] = getenv('MYSQL_PASSWORD');
    $CONFIG['dbhost'] = getenv('MYSQL_HOST');
    $autoconfig_enabled = true;
} elseif (getenv('POSTGRES_DB_FILE') && getenv('POSTGRES_USER_FILE') && getenv('POSTGRES_PASSWORD_FILE') && getenv('POSTGRES_HOST')) {
    $CONFIG['dbtype'] = 'pgsql';
    $CONFIG['dbname'] = trim(file_get_contents(getenv('POSTGRES_DB_FILE')));
    $CONFIG['dbuser'] = trim(file_get_contents(getenv('POSTGRES_USER_FILE')));
    $CONFIG['dbpassword'] = trim(file_get_contents(getenv('POSTGRES_PASSWORD_FILE')));
    $CONFIG['dbhost'] = getenv('POSTGRES_HOST');
    $autoconfig_enabled = true;
} elseif (getenv('POSTGRES_DB') && getenv('POSTGRES_USER') && getenv('POSTGRES_PASSWORD') && getenv('POSTGRES_HOST')) {
    $CONFIG['dbtype'] = 'pgsql';
    $CONFIG['dbname'] = getenv('POSTGRES_DB');
    $CONFIG['dbuser'] = getenv('POSTGRES_USER');
    $CONFIG['dbpassword'] = getenv('POSTGRES_PASSWORD');
    $CONFIG['dbhost'] = getenv('POSTGRES_HOST');
    $autoconfig_enabled = true;
}

if ($autoconfig_enabled) {
    $CONFIG['datadirectory'] = getenv('NEXTCLOUD_DATA_DIR') ?: '/var/www/html/data';
}
