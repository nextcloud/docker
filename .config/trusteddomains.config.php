<?php

if (getenv('NEXTCLOUD_TRUSTED_DOMAINS')) {
  // Get originaly configured values
  include(__DIR__.'/config.php');

  // Add environment variables
  $CONFIG = array(
    'trusted_domains' => array_merge($CONFIG['trusted_domains'],array_map(function($domain){return trim($domain);},explode(",",getenv('NEXTCLOUD_TRUSTED_DOMAINS'))))
  );
}
