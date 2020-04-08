<?php

$trustedProxies = getenv('TRUSTED_PROXIES');

if ($trustedProxies) {
  $trustedProxies = array_filter(array_map('trim', explode(' ', $trustedProxies)));
} else {
  $trustedProxies = null;
}

$CONFIG['trusted_proxies'] = $trustedProxies;