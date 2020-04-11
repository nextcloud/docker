<?php
$overwriteHost = getenv('OVERWRITEHOST');
if ($overwriteHost) {
  $CONFIG['overwritehost'] = $overwriteHost;
} else {
  $CONFIG['overwritehost'] = null;
}

$overwriteProtocol = getenv('OVERWRITEPROTOCOL');
if ($overwriteProtocol) {
  $CONFIG['overwriteprotocol'] = $overwriteProtocol;
} else {
  $CONFIG['overwriteprotocol'] = null;
}

$overwriteWebRoot = getenv('OVERWRITEWEBROOT');
if ($overwriteWebRoot) {
  $CONFIG['overwritewebroot'] = $overwriteWebRoot;
} else {
  $CONFIG['overwritewebroot'] = null;
}

$overwriteCondAddr = getenv('OVERWRITECONDADDR');
if ($overwriteCondAddr) {
  $CONFIG['overwritecondaddr'] = $overwriteCondAddr;
} else {
  $CONFIG['overwritecondaddr'] = null;
}

$trustedProxies = getenv('TRUSTED_PROXIES');
if ($trustedProxies) {
  $CONFIG['trusted_proxies'] = array_filter(array_map('trim', explode(' ', $trustedProxies)));
} else {
  $CONFIG['trusted_proxies'] = null;
}
