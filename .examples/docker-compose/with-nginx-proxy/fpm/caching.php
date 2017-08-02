<?
$CONFIG = array (
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'memcache.locking' => '\\OC\\Memcache\\Redis',
  'filelocking.enabled' => 'true',
  'redis' =>
  array (
    'host' => 'redis',
    'port' => 6379,
  ),
);
?>
