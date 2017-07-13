<?php
$AUTOCONFIG = array(
  'directory'     => '/var/www/html/data',
  'dbtype'        => 'pgsql',
  'dbname'        => getenv('POSTGRES_DB'),
  'dbuser'        => getenv('POSTGRES_USER'),
  'dbpass'        => getenv('POSTGRES_PASSWORD'),
  'dbhost'        => 'db',
  'dbtableprefix' => '',
);
