<?php
$overwriteHost = getenv('OVERWRITEHOST');
if ($overwriteHost) {
  $CONFIG['overwritehost'] = $overwriteHost;
}

$overwriteProtocol = getenv('OVERWRITEPROTOCOL');
if ($overwriteProtocol) {
  $CONFIG['overwriteprotocol'] = $overwriteProtocol;
}

$overwriteCliUrl = getenv('OVERWRITECLIURL');
if ($overwriteCliUrl) {
  $CONFIG['overwrite.cli.url'] = $overwriteCliUrl;
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
  $CONFIG['trusted_proxies'] = array_filter(array_map('trim', explode(' ', $trustedProxies)));
}

$forwardedForHeaders = getenv('FORWARDED_FOR_HEADERS');
if ($forwardedForHeaders) {
  $CONFIG['forwarded_for_headers'] = array_filter(array_map('trim', explode(' ', $forwardedForHeaders)));
}
