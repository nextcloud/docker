<?php

if ($trustedProxies = getenv('TRUSTED_PROXIES')) {
  $CONFIG['trusted_proxies'] = explode(' ', $trustedProxies);
} else {
  $CONFIG['trusted_proxies'] = ['172.16.0.0/12', '192.168.0.0/16', '10.0.0.0/8'];
}