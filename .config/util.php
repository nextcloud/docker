<?php

declare(strict_types=1);

/**
 * Gets the value of an environment variable or the contents of the file
 * at the path specified by its value if it exists with a suffix of "_FILE"
 */
function getFileEnv(string $envVarName, ?string $defaultValue): ?string {
    $FILE_ENV_VAR_SUFFIX = "_FILE";

    $fileEnvVarName = "$envVarName$FILE_ENV_VAR_SUFFIX";
    $filename = getenv($fileEnvVarName);
    $envVarValue = getenv($envVarName);

    $configValue = null;
    if ($filename && file_exists($filename)) {
        $configValue = trim(file_get_contents($filename));
    } else if ($envVarValue) {
        $configValue = $envVarValue;
    } else if ($defaultValue) {
        $configValue = $defaultValue;
    }
    return $configValue;
}

?>
