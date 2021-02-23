<?php
if (getenv('OBJECTSTORE_S3_BUCKET')) {
  $use_ssl = getenv('OBJECTSTORE_S3_SSL');
  $use_path = getenv('OBJECTSTORE_S3_USEPATH_STYLE');
  $autocreate = getenv('OBJECTSTORE_S3_AUTOCREATE');
  $CONFIG = array(
    'objectstore' => array(
      'class' => '\OC\Files\ObjectStore\S3',
      'arguments' => array(
        'bucket' => getenv('OBJECTSTORE_S3_BUCKET'),
        'key' => getenv('OBJECTSTORE_S3_KEY') ?: '',
        'secret' => getenv('OBJECTSTORE_S3_SECRET') ?: '',
        'region' => getenv('OBJECTSTORE_S3_REGION') ?: '',
        'hostname' => getenv('OBJECTSTORE_S3_HOST') ?: '',
        'port' => getenv('OBJECTSTORE_S3_PORT') ?: '',
        'objectPrefix' => getenv("OBJECTSTORE_S3_OBJECT_PREFIX") ? getenv("OBJECTSTORE_S3_OBJECT_PREFIX") : "urn:oid:",
        'autocreate' => (strtolower($autocreate) === 'false' || $autocreate == false) ? false : true,
        'use_ssl' => (strtolower($use_ssl) === 'false' || $use_ssl == false) ? false : true,
        // required for some non Amazon S3 implementations
        'use_path_style' => $use_path == true && strtolower($use_path) !== 'false'
      )
    )
  );
} 
