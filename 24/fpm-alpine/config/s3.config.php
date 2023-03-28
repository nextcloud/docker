<?php
if (getenv('OBJECTSTORE_S3_BUCKET')) {
  $use_ssl = getenv('OBJECTSTORE_S3_SSL');
  $use_path = getenv('OBJECTSTORE_S3_USEPATH_STYLE');
  $use_legacyauth = getenv('OBJECTSTORE_S3_LEGACYAUTH');
  $autocreate = getenv('OBJECTSTORE_S3_AUTOCREATE');
  $CONFIG = array(
    'objectstore' => array(
      'class' => '\OC\Files\ObjectStore\S3',
      'arguments' => array(
        'bucket' => getenv('OBJECTSTORE_S3_BUCKET'),
        'region' => getenv('OBJECTSTORE_S3_REGION') ?: '',
        'hostname' => getenv('OBJECTSTORE_S3_HOST') ?: '',
        'port' => getenv('OBJECTSTORE_S3_PORT') ?: '',
        'objectPrefix' => getenv("OBJECTSTORE_S3_OBJECT_PREFIX") ? getenv("OBJECTSTORE_S3_OBJECT_PREFIX") : "urn:oid:",
        'autocreate' => (strtolower($autocreate) === 'false' || $autocreate == false) ? false : true,
        'use_ssl' => (strtolower($use_ssl) === 'false' || $use_ssl == false) ? false : true,
        // required for some non Amazon S3 implementations
        'use_path_style' => $use_path == true && strtolower($use_path) !== 'false',
        // required for older protocol versions
        'legacy_auth' => $use_legacyauth == true && strtolower($use_legacyauth) !== 'false'
      )
    )
  );

  if (getenv('OBJECTSTORE_S3_KEY_FILE') && file_exists(getenv('OBJECTSTORE_S3_KEY_FILE'))) {
    $CONFIG['objectstore']['arguments']['key'] = trim(file_get_contents(getenv('OBJECTSTORE_S3_KEY_FILE')));
  } elseif (getenv('OBJECTSTORE_S3_KEY')) {
    $CONFIG['objectstore']['arguments']['key'] = getenv('OBJECTSTORE_S3_KEY');
  } else {
    $CONFIG['objectstore']['arguments']['key'] = '';
  }

  if (getenv('OBJECTSTORE_S3_SECRET_FILE') && file_exists(getenv('OBJECTSTORE_S3_SECRET_FILE'))) {
    $CONFIG['objectstore']['arguments']['secret'] = trim(file_get_contents(getenv('OBJECTSTORE_S3_SECRET_FILE')));
  } elseif (getenv('OBJECTSTORE_S3_SECRET')) {
    $CONFIG['objectstore']['arguments']['secret'] = getenv('OBJECTSTORE_S3_SECRET');
  } else {
    $CONFIG['objectstore']['arguments']['secret'] = '';
  }
} 
