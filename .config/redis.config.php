<?php
if (getenv('REDIS_HOST')) {
  $CONFIG = array (
    'memcache.distributed' => '\OC\Memcache\Redis',
    'memcache.locking' => '\OC\Memcache\Redis',
    'redis' => array(
      'host' => getenv('REDIS_HOST'),
    ),
  );
  if(getenv('REDIS_HOST_PORT') !== false) {
    $CONFIG['redis']['port'] = getenv('REDIS_HOST_PORT');
  }
  else if (getenv('REDIS_HOST')[0] != '/') {
    $CONFIG['redis']['port'] = 6379;
  }
}

