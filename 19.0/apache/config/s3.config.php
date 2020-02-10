<?php
if (getenv('OBJECTSTORE_S3_HOST')) {
  $CONFIG = array (
    'objectstore' => array(
      'class' => '\\OC\\Files\\ObjectStore\\S3',
      'arguments' => array(
        'bucket' => getenv('OBJECTSTORE_S3_BUCKET'),
        'autocreate' => getenv('OBJECTSTORE_S3_AUTOCREATE') ?: true,
        'key'    => getenv('OBJECTSTORE_S3_KEY'),
        'secret' => getenv('OBJECTSTORE_S3_SECRET'),
        'hostname' => getenv('OBJECTSTORE_S3_HOST'),
        'port' => getenv('OBJECTSTORE_S3_PORT'),
        'use_ssl' => getenv('OBJECTSTORE_S3_SSL') ?: true,
        'region' => getenv('OBJECTSTORE_S3_REGION') ?: "optional",
        // required for some non Amazon S3 implementations
        'use_path_style' => getenv('OBJECTSTORE_S3_USEPATH_STYLE') ?: true,
      ),
    ),
  );
}
