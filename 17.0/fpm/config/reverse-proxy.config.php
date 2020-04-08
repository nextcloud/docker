<?php
$overwritehost = getenv('OVERWRITEHOST');
if ($overwritehost) {
  $CONFIG['overwritehost'] = $overwritehost;
} else {
  $CONFIG['overwritehost'] = null;
}

$overwriteprotocol = getenv('OVERWRITEPROTOCOL');
if ($overwriteprotocol) {
  $CONFIG['overwriteprotocol'] = $overwriteprotocol;
} else {
  $CONFIG['overwriteprotocol'] = null;
}

$overwritewebroot = getenv('OVERWRITEWEBROOT');
if ($overwritewebroot) {
  $CONFIG['overwritewebroot'] = $overwritewebroot;
} else {
  $CONFIG['overwritewebroot'] = null;
}

$overwritecondaddr = getenv('OVERWRITECONDADDR');
if ($overwritecondaddr) {
  $CONFIG['overwritecondaddr'] = $overwritecondaddr;
} else {
  $CONFIG['overwritecondaddr'] = null;
}

$trusted_proxies = getenv('TRUSTED_PROXIES');
if ($trusted_proxies) {
  $CONFIG['trusted_proxies'] = explode(',', $trusted_proxies);
} else {
  $CONFIG['trusted_proxies'] = null;
}
