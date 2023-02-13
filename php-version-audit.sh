#!/usr/bin/env bash
set -eo pipefail

# Run PHP Version Audit against all the base docker images to alert if they are EOL or have CVEs
# See https://www.github.developerdan.com/php-version-audit/

# Parse out the "FROM php:" tags from the Dockerfiles
php_tags=$(find . -type f -name Dockerfile -not -path '*/.*' | xargs cat | grep "FROM php:" | sort -u | sed 's/.*://')

# For each image, get the full php version
php_versions=$(echo "${php_tags}" | while read -r tag; do
  docker run --pull always --rm --entrypoint=php "php:${tag}" -r 'echo phpversion()."\n";';
done | sort -u)

# Run all the php version through php-version-audit with the '--fail-security' flag
# to generate an exit code if a CVE is found or the support is EOL
echo "${php_versions}" | while read -r version; do
  docker run --rm lightswitch05/php-version-audit:latest --fail-security --version="${version}";
done
