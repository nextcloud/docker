<?php
$AUTOCONFIG = array(
  'directory'     => '/var/www/html/data',
  'dbtype'        => 'mysql',
  'dbname'        => getenv('MYSQL_DATABASE'),
  'dbuser'        => getenv('MYSQL_USER'),
  'dbpass'        => getenv('MYSQL_PASSWORD'),
  'dbhost'        => 'db',
  'dbtableprefix' => '',
);
