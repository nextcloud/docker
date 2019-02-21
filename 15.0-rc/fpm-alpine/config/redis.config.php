<?php
if (getenv('REDIS_HOST')) {
  $CONFIG = array (
    'memcache.distributed' => '\OC\Memcache\Redis',
    'memcache.locking' => '\OC\Memcache\Redis',
    'redis' => array(
      'host' => getenv('REDIS_HOST'),
      'port' => getenv('REDIS_HOST_PORT') ?: 6379,
    ),
  );
}

