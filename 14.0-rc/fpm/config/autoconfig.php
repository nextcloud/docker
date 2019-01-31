<?php

$autoconfig_enabled = false;

if (getenv('SQLITE_DATABASE')) {
    $AUTOCONFIG["dbtype"] = "sqlite";
    $AUTOCONFIG["dbname"] = getenv('SQLITE_DATABASE');
    $autoconfig_enabled = true;
} elseif (getenv('MYSQL_DATABASE') && getenv('MYSQL_USER') && getenv('MYSQL_PASSWORD') && getenv('MYSQL_HOST')) {
    $AUTOCONFIG["dbtype"] = "mysql";
    $AUTOCONFIG["dbname"] = getenv('MYSQL_DATABASE');
    $AUTOCONFIG["dbuser"] = getenv('MYSQL_USER');
    $AUTOCONFIG["dbpass"] = getenv('MYSQL_PASSWORD');
    $AUTOCONFIG["dbhost"] = getenv('MYSQL_HOST');
    $autoconfig_enabled = true;
} elseif (getenv('POSTGRES_DB') && getenv('POSTGRES_USER') && getenv('POSTGRES_PASSWORD') && getenv('POSTGRES_HOST')) {
    $AUTOCONFIG["dbtype"] = "pgsql";
    $AUTOCONFIG["dbname"] = getenv('POSTGRES_DB');
    $AUTOCONFIG["dbuser"] = getenv('POSTGRES_USER');
    $AUTOCONFIG["dbpass"] = getenv('POSTGRES_PASSWORD');
    $AUTOCONFIG["dbhost"] = getenv('POSTGRES_HOST');
    $autoconfig_enabled = true;
}

if ($autoconfig_enabled) {
    $AUTOCONFIG["dbtableprefix"] = getenv('NEXTCLOUD_TABLE_PREFIX') ?: "";

    $AUTOCONFIG["directory"] = getenv('NEXTCLOUD_DATA_DIR') ?: "/var/www/html/data";
}
