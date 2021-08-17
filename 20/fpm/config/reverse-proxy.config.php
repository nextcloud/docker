<?php
$overwriteHost = getenv('OVERWRITEHOST');
if ($overwriteHost) {
  $CONFIG['overwritehost'] = $overwriteHost;
}

$overwriteProtocol = getenv('OVERWRITEPROTOCOL');
if ($overwriteProtocol) {
  $CONFIG['overwriteprotocol'] = $overwriteProtocol;
}

$overwriteWebRoot = getenv('OVERWRITEWEBROOT');
if ($overwriteWebRoot) {
  $CONFIG['overwritewebroot'] = $overwriteWebRoot;
}

$overwriteCondAddr = getenv('OVERWRITECONDADDR');
if ($overwriteCondAddr) {
  $CONFIG['overwritecondaddr'] = $overwriteCondAddr;
}

$trustedProxies = getenv('TRUSTED_PROXIES');
if ($trustedProxies) {
  $CONFIG['trusted_proxies'] = array_values(array_unique(array_map('gethostbyname', array_filter(explode(' ', $trustedProxies)))));
}
