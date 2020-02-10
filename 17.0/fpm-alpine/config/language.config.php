<?php
$CONFIG = array(
  'default_language' => getenv('DEFAULT_LANGUAGE') ?: 'en',
  'force_language' => getenv('FORCE_LANGUAGE') ?: false,
  'default_locale' => getenv('DEFAULT_LOCALE') ?: 'en_US',
  'force_locale' => getenv('FORCE_LOCALE') ?: false,
);
