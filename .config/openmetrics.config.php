<?php

$openmetricsAllowedClients = getenv('OPENMETRICS_ALLOWED_CLIENTS');
if ($openmetricsAllowedClients) {
  $CONFIG['openmetrics_allowed_clients'] = array_filter(array_map('trim', explode(',', $openmetricsAllowedClients)));
}
