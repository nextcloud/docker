<?php
if (getenv('OVERWRITEHOST')) {
  $CONFIG['overwritehost'] = getenv('OVERWRITEHOST');
} else {
  $CONFIG['overwritehost'] = '';
}

if (getenv('OVERWRITEPROTOCOL')) {
  $CONFIG['overwriteprotocol'] = getenv('OVERWRITEPROTOCOL');
} else {
  $CONFIG['overwriteprotocol'] = '';
}

if (getenv('OVERWRITEWEBROOT')) {
  $CONFIG['overwritewebroot'] = getenv('OVERWRITEWEBROOT');
} else {
  $CONFIG['overwritewebroot'] = '';
}

if (getenv('OVERWRITECONDADDR')) {
  $CONFIG['overwritecondaddr'] = getenv('OVERWRITECONDADDR');
} else {
  $CONFIG['overwritecondaddr'] = '';
}

if (getenv('TRUSTED_PROXIES')) {
  $CONFIG['trusted_proxies'] = explode(',', getenv('TRUSTED_PROXIES'));
} else {
  $CONFIG['trusted_proxies'] = [];
}
