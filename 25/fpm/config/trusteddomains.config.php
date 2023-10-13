<?php

if (getenv('NEXTCLOUD_TRUSTED_DOMAINS')) {
  $CONFIG = array(
    'trusted_domains' => array_map(function($domain){return trim($domain);},explode(",",getenv('NEXTCLOUD_TRUSTED_DOMAINS')))
  );
}
