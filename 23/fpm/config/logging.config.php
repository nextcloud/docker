<?php

$CONFIG = array(
    'loglevel' => getenv('LOGLEVEL') ?: 2,
    'logtimezone' => getenv('LOGTIMEZONE') ?: 'UTC',
    'syslog_tag' => getenv('LOGTAG') ?: 'Nextcloud',
);

if (getenv('LOGFILE')) {
    $CONFIG['logfile'] = getenv('LOGFILE');
} else {
    $CONFIG['logfile'] = getenv('NEXTCLOUD_DATA_DIR') ?: '/var/www/nextcloud' + '/nextcloud.log';
}