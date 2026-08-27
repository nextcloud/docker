<?php
if (getenv('REDIS_CLUSTER_SEEDS')) {
  $redisClusterSeeds = array_values(
    array_filter(
      array_map('trim', explode(',', getenv('REDIS_CLUSTER_SEEDS'))),
      function ($seed) {
        return $seed !== '';
      }
    )
  );

  $CONFIG = array(
    'memcache.distributed' => '\OC\Memcache\Redis',
    'memcache.locking' => '\OC\Memcache\Redis',
    'redis.cluster' => array(
      'seeds' => $redisClusterSeeds,
      'password' => getenv('REDIS_HOST_PASSWORD_FILE') ? trim(file_get_contents(getenv('REDIS_HOST_PASSWORD_FILE'))) : (string) getenv('REDIS_HOST_PASSWORD'),
    ),
  );

  if (getenv('REDIS_HOST_USER') !== false) {
    $CONFIG['redis.cluster']['user'] = (string) getenv('REDIS_HOST_USER');
  }
} elseif (getenv('REDIS_HOST')) {
  $CONFIG = array(
    'memcache.distributed' => '\OC\Memcache\Redis',
    'memcache.locking' => '\OC\Memcache\Redis',
    'redis' => array(
      'host' => getenv('REDIS_HOST'),
      'password' => getenv('REDIS_HOST_PASSWORD_FILE') ? trim(file_get_contents(getenv('REDIS_HOST_PASSWORD_FILE'))) : (string) getenv('REDIS_HOST_PASSWORD'),
    ),
  );

  if (getenv('REDIS_HOST_PORT') !== false) {
    $CONFIG['redis']['port'] = (int) getenv('REDIS_HOST_PORT');
  } elseif (getenv('REDIS_HOST')[0] != '/') {
    $CONFIG['redis']['port'] = 6379;
  }

  if (getenv('REDIS_HOST_USER') !== false) {
    $CONFIG['redis']['user'] = (string) getenv('REDIS_HOST_USER');
  }
}
