<?php
if (getenv('REDIS_HOST')) {
  $CONFIG = array (
    'memcache.locking' => '\OC\Memcache\Redis',
    'redis' => array(
      'host' => getenv('REDIS_HOST'),
      'port' => getenv('REDIS_PORT') ?: 6379,
    ),
  );
}