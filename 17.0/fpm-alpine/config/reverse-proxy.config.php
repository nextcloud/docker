<?php
if (getenv('OVERWRITEHOST')) {
  $CONFIG['overwritehost'] = getenv('OVERWRITEHOST');
} else {
  $CONFIG['overwritehost'] = null;
}

if (getenv('OVERWRITEPROTOCOL')) {
  $CONFIG['overwriteprotocol'] = getenv('OVERWRITEPROTOCOL');
} else {
  $CONFIG['overwriteprotocol'] = null;
}

if (getenv('OVERWRITEWEBROOT')) {
  $CONFIG['overwritewebroot'] = getenv('OVERWRITEWEBROOT');
} else {
  $CONFIG['overwritewebroot'] = null;
}

if (getenv('OVERWRITECONDADDR')) {
  $CONFIG['overwritecondaddr'] = getenv('OVERWRITECONDADDR');
} else {
  $CONFIG['overwritecondaddr'] = null;
}

if (getenv('TRUSTED_PROXIES')) {
  $CONFIG['trusted_proxies'] = explode(',', getenv('TRUSTED_PROXIES'));
} else {
  $CONFIG['trusted_proxies'] = null;
}
