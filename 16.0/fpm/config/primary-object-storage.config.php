<?php
if (getenv('S3_BUCKETNAME') && getenv('S3_ACCESS_KEY') && getenv('S3_SECRET_KEY')) {
    // Set required configurations
    $CONFIG = array (
        'objectstore' => array (
            'class' => '\\OC\\Files\\ObjectStore\\S3',
            'arguments' => array (
                'bucket' => getenv('S3_BUCKETNAME'),
                'key' => getenv('S3_ACCESS_KEY'),
                'secret' => getenv('S3_SECRET_KEY'),
            )
        )
    );

    // Set optional configurations
    if (getenv('S3_AUTOCREATE') !== false) {
        $CONFIG['objectstore']['arguments']['autocreate'] = (bool) getenv('S3_AUTOCREATE');
    }

    if (getenv('S3_HOST') !== false) {
        $CONFIG['objectstore']['arguments']['hostname'] = getenv('S3_HOST');
    }

    if (getenv('S3_PORT') !== false) {
        $CONFIG['objectstore']['arguments']['port'] = (int) getenv('S3_PORT');
    }

    if (getenv('S3_REGION') !== false) {
        $CONFIG['objectstore']['arguments']['region'] = getenv('S3_REGION');
    }

    if (getenv('S3_USE_SSL') !== false) {
        $CONFIG['objectstore']['arguments']['use_ssl'] = (bool) getenv('S3_USE_SSL');
    }

    if (getenv('S3_USE_PATH_STYLE') !== false) {
        $CONFIG['objectstore']['arguments']['use_path_style'] = (bool) getenv('S3_USE_PATH_STYLE');
    }
}
