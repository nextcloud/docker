<?php
if (getenv('OVERWRITEHOST')) {
  $CONFIG['overwritehost'] = getenv('OVERWRITEHOST');
}

if (getenv('OVERWRITEPROTOCOL')) {
  $CONFIG['overwriteprotocol'] = getenv('OVERWRITEPROTOCOL');
}

if (getenv('OVERWRITEWEBROOT')) {
  $CONFIG['overwritewebroot'] = getenv('OVERWRITEWEBROOT');
}

if (getenv('OVERWRITECONDADDR')) {
  $CONFIG['overwritecondaddr'] = getenv('OVERWRITECONDADDR');
}

if (getenv('TRUSTED_PROXIES')) {
  $CONFIG['trusted_proxies'] = explode(',', getenv('TRUSTED_PROXIES'));
}
