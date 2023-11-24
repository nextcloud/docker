#!/usr/bin/env bash
set -eo pipefail

declare -A alpine_version=(
	[default]='3.18'
)

declare -A debian_version=(
	[default]='bookworm'
)

declare -A php_version=(
	[default]='8.2'
)

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
	[fpm-alpine]='php-fpm'
)

declare -A base=(
	[apache]='debian'
	[fpm]='debian'
	[fpm-alpine]='alpine'
)

declare -A extras=(
	[apache]='\nRUN a2enmod headers rewrite remoteip ; \\\n    { \\\n     echo '\''RemoteIPHeader X-Real-IP'\''; \\\n     echo '\''RemoteIPInternalProxy 10.0.0.0/8'\''; \\\n     echo '\''RemoteIPInternalProxy 172.16.0.0/12'\''; \\\n     echo '\''RemoteIPInternalProxy 192.168.0.0/16'\''; \\\n    } > /etc/apache2/conf-available/remoteip.conf; \\\n    a2enconf remoteip\n\n# set apache config LimitRequestBody\nENV APACHE_BODY_LIMIT 1073741824\nRUN { \\\n     echo '\''LimitRequestBody ${APACHE_BODY_LIMIT}'\''; \\\n    } > /etc/apache2/conf-available/apache-limits.conf; \\\n    a2enconf apache-limits'
	[fpm]=''
	[fpm-alpine]=''
)

declare -A crontab_int=(
	[default]='5'
)

apcu_version="$(
	git ls-remote --tags https://github.com/krakjoe/apcu.git \
		| cut -d/ -f3 \
		| grep -viE -- 'rc|b' \
		| sed -E 's/^v//' \
		| sort -V \
		| tail -1
)"

memcached_version="$(
	git ls-remote --tags https://github.com/php-memcached-dev/php-memcached.git \
		| cut -d/ -f3 \
		| grep -viE -- 'rc|b' \
		| sed -E 's/^[rv]//' \
		| sort -V \
		| tail -1
)"

redis_version="$(
	git ls-remote --tags https://github.com/phpredis/phpredis.git \
		| cut -d/ -f3 \
		| grep -viE '[a-z]' \
		| tr -d '^{}' \
		| sort -V \
		| tail -1
)"

imagick_version="$(
	git ls-remote --tags https://github.com/mkoppanen/imagick.git \
		| cut -d/ -f3 \
		| grep -viE '[a-z]' \
		| tr -d '^{}' \
		| sort -V \
		| tail -1
)"

declare -A pecl_versions=(
	[APCu]="$apcu_version"
	[memcached]="$memcached_version"
	[redis]="$redis_version"
	[imagick]="$imagick_version"
)

variants=(
	apache
	fpm
	fpm-alpine
)

min_version='26'

# version_greater_or_equal A B returns whether A >= B
function version_greater_or_equal() {
	[[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || "$1" == "$2" ]];
}

function create_variant() {
	dir="$1/$variant"
	alpineVersion=${alpine_version[$version]-${alpine_version[default]}}
	debianVersion=${debian_version[$version]-${debian_version[default]}}
	phpVersion=${php_version[$version]-${php_version[default]}}
	crontabInt=${crontab_int[$version]-${crontab_int[default]}}
	url="https://download.nextcloud.com/server/releases/nextcloud-$fullversion.tar.bz2"
	ascUrl="https://download.nextcloud.com/server/releases/nextcloud-$fullversion.tar.bz2.asc"

	# Create the version+variant directory with a Dockerfile.
	mkdir -p "$dir"

	template="Dockerfile-${base[$variant]}.template"
	echo "# DO NOT EDIT: created by update.sh from $template" > "$dir/Dockerfile"
	cat "$template" >> "$dir/Dockerfile"

	echo "updating $fullversion [$1] $variant"

	# Replace the variables.
	sed -ri -e '
		s/%%ALPINE_VERSION%%/'"$alpineVersion"'/g;
		s/%%DEBIAN_VERSION%%/'"$debianVersion"'/g;
		s/%%PHP_VERSION%%/'"$phpVersion"'/g;
		s/%%VARIANT%%/'"$variant"'/g;
		s/%%VERSION%%/'"$fullversion"'/g;
		s/%%DOWNLOAD_URL%%/'"$(sed -e 's/[\/&]/\\&/g' <<< "$url")"'/g;
		s/%%DOWNLOAD_URL_ASC%%/'"$(sed -e 's/[\/&]/\\&/g' <<< "$ascUrl")"'/g;
		s/%%CMD%%/'"${cmd[$variant]}"'/g;
		s|%%VARIANT_EXTRAS%%|'"${extras[$variant]}"'|g;
		s/%%APCU_VERSION%%/'"${pecl_versions[APCu]}"'/g;
		s/%%MEMCACHED_VERSION%%/'"${pecl_versions[memcached]}"'/g;
		s/%%REDIS_VERSION%%/'"${pecl_versions[redis]}"'/g;
		s/%%IMAGICK_VERSION%%/'"${pecl_versions[imagick]}"'/g;
		s/%%CRONTAB_INT%%/'"$crontabInt"'/g;
	' "$dir/Dockerfile"

	# Copy the shell scripts
	for name in entrypoint cron; do
		cp "docker-$name.sh" "$dir/$name.sh"
	done

	# Copy the upgrade.exclude
	cp upgrade.exclude "$dir/"

	# Copy the config directory
	cp -rT .config "$dir/config"

	# Remove Apache config if we're not an Apache variant.
	if [ "$variant" != "apache" ]; then
		rm "$dir/config/apache-pretty-urls.config.php"
	fi

	# Add variant to versions.json
	[ "${base[$variant]}" == "alpine" ] && baseVersion="$alpineVersion" || baseVersion="$debianVersion"
	versionVariantsJson="$(jq -e \
		--arg version "$version" --arg variant "$variant" --arg base "${base[$variant]}" --arg baseVersion "$baseVersion" --arg phpVersion "$phpVersion" \
		'.[$version].variants[$variant] = {"variant": $variant, "base": $base, "baseVersion": $baseVersion, "phpVersion": $phpVersion}' versions.json)"
	versionJson="$(jq -e \
		--arg version "$version" --arg fullversion "$fullversion" --arg url "$url" --arg ascUrl "$ascUrl" --argjson variants "$versionVariantsJson" \
		'.[$version] = {"branch": $version, "version": $fullversion, "url": $url, "ascUrl": $ascUrl, "variants": $variants[$version].variants}' versions.json)"
	printf '%s\n' "$versionJson" > versions.json
}

curl -fsSL 'https://download.nextcloud.com/server/releases/' |tac|tac| \
	grep -oE 'nextcloud-[[:digit:]]+(\.[[:digit:]]+){2}' | \
	grep -oE '[[:digit:]]+(\.[[:digit:]]+){2}' | \
	sort -uV | \
	tail -1 > latest.txt

find . -maxdepth 1 -type d -regextype sed -regex '\./[[:digit:]]\+\.[[:digit:]]\+\(-rc\|-beta\|-alpha\)\?' -exec rm -r '{}' \;

printf '%s' "{}" > versions.json

fullversions=( $( curl -fsSL 'https://download.nextcloud.com/server/releases/' |tac|tac| \
	grep -oE 'nextcloud-[[:digit:]]+(\.[[:digit:]]+){2}' | \
	grep -oE '[[:digit:]]+(\.[[:digit:]]+){2}' | \
	sort -urV ) )
versions=( $( printf '%s\n' "${fullversions[@]}" | cut -d. -f1 | sort -urV ) )

for version in "${versions[@]}"; do
	fullversion="$( printf '%s\n' "${fullversions[@]}" | grep -E "^$version" | head -1 )"

	if version_greater_or_equal "$version" "$min_version"; then
		for variant in "${variants[@]}"; do
			create_variant "$version"
		done
	fi
done
