#!/bin/bash
set -eo pipefail

declare -A php_version=(
	[default]='7.3'
	[14.0]='7.2'
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
	[apache]='\nRUN a2enmod rewrite remoteip ;\\\n    {\\\n     echo RemoteIPHeader X-Real-IP ;\\\n     echo RemoteIPTrustedProxy 10.0.0.0/8 ;\\\n     echo RemoteIPTrustedProxy 172.16.0.0/12 ;\\\n     echo RemoteIPTrustedProxy 192.168.0.0/16 ;\\\n    } > /etc/apache2/conf-available/remoteip.conf;\\\n    a2enconf remoteip'
	[fpm]=''
	[fpm-alpine]=''
)

apcu_version="$(
	git ls-remote --tags https://github.com/krakjoe/apcu.git \
		| cut -d/ -f3 \
		| grep -vE -- '-rc|-b' \
		| sed -E 's/^v//' \
		| sort -V \
		| tail -1
)"

memcached_version="$(
	git ls-remote --tags https://github.com/php-memcached-dev/php-memcached.git \
		| cut -d/ -f3 \
		| grep -vE -- '-rc|-b' \
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
	[redis]="4.3.0"
	[imagick]="$imagick_version"
)

variants=(
	apache
	fpm
	fpm-alpine
)

min_version='14.0'

# version_greater_or_equal A B returns whether A >= B
function version_greater_or_equal() {
	[[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || "$1" == "$2" ]];
}

# checks if the the rc is already released
function check_released() {
	printf '%s\n' "${fullversions[@]}" | grep -qE "^$( echo "$1" | grep -oE '[[:digit:]]+(\.[[:digit:]]+){2}' )"
}

# checks if the the beta has already a rc
function check_rc_released() {
	printf '%s\n' "${fullversions_rc[@]}" | grep -qE "^$( echo "$1" | grep -oE '[[:digit:]]+(\.[[:digit:]]+){2}' )"
}

# checks if the the alpha has already a beta
function check_beta_released() {
	printf '%s\n' "${fullversions_beta[@]}" | grep -qE "^$( echo "$1" | grep -oE '[[:digit:]]+(\.[[:digit:]]+){2}' )"
}

travisEnv=

function create_variant() {
	dir="$1/$variant"
	phpVersion=${php_version[$version]-${php_version[default]}}

	# Create the version+variant directory with a Dockerfile.
	mkdir -p "$dir"

	template="Dockerfile-${base[$variant]}.template"
	echo "# DO NOT EDIT: created by update.sh from $template" > "$dir/Dockerfile"
	cat "$template" >> "$dir/Dockerfile"

	echo "updating $fullversion [$1] $variant"

	# Replace the variables.
	sed -ri -e '
		s/%%PHP_VERSION%%/'"$phpVersion"'/g;
		s/%%VARIANT%%/'"$variant"'/g;
		s/%%VERSION%%/'"$fullversion"'/g;
		s/%%BASE_DOWNLOAD_URL%%/'"$2"'/g;
		s/%%CMD%%/'"${cmd[$variant]}"'/g;
		s|%%VARIANT_EXTRAS%%|'"${extras[$variant]}"'|g;
		s/%%APCU_VERSION%%/'"${pecl_versions[APCu]}"'/g;
		s/%%MEMCACHED_VERSION%%/'"${pecl_versions[memcached]}"'/g;
		s/%%REDIS_VERSION%%/'"${pecl_versions[redis]}"'/g;
		s/%%IMAGICK_VERSION%%/'"${pecl_versions[imagick]}"'/g;
	' "$dir/Dockerfile"

	if [[ "$phpVersion" != 7.3 ]]; then
		sed -ri \
			-e '/libzip-dev/d' \
			"$dir/Dockerfile"
	fi

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

	for arch in i386 amd64; do
		travisEnv='    - env: VERSION='"$1"' VARIANT='"$variant"' ARCH='"$arch"'\n'"$travisEnv"
	done
}

find . -maxdepth 1 -type d -regextype sed -regex '\./[[:digit:]]\+\.[[:digit:]]\+\(-rc\|-beta\|-alpha\)\?' -exec rm -r '{}' \;

fullversions=( $( curl -fsSL 'https://download.nextcloud.com/server/releases/' |tac|tac| \
	grep -oE 'nextcloud-[[:digit:]]+(\.[[:digit:]]+){2}' | \
	grep -oE '[[:digit:]]+(\.[[:digit:]]+){2}' | \
	sort -urV ) )
versions=( $( printf '%s\n' "${fullversions[@]}" | cut -d. -f1-2 | sort -urV ) )
for version in "${versions[@]}"; do
	fullversion="$( printf '%s\n' "${fullversions[@]}" | grep -E "^$version" | head -1 )"

	if version_greater_or_equal "$version" "$min_version"; then

		for variant in "${variants[@]}"; do

			create_variant "$version" "https:\/\/download.nextcloud.com\/server\/releases"
		done
	fi
done

fullversions_rc=( $( curl -fsSL 'https://download.nextcloud.com/server/prereleases/' |tac|tac| \
	grep -oE 'nextcloud-[[:digit:]]+(\.[[:digit:]]+){2}RC[[:digit:]]+' | \
	grep -oE '[[:digit:]]+(\.[[:digit:]]+){2}RC[[:digit:]]+' | \
	sort -urV ) )
versions_rc=( $( printf '%s\n' "${fullversions_rc[@]}" | cut -d. -f1-2 | sort -urV ) )
for version in "${versions_rc[@]}"; do
	fullversion="$( printf '%s\n' "${fullversions_rc[@]}" | grep -E "^$version" | head -1 )"

	if version_greater_or_equal "$version" "$min_version"; then

		if ! check_released "$fullversion"; then

			for variant in "${variants[@]}"; do

				create_variant "$version-rc" "https:\/\/download.nextcloud.com\/server\/prereleases"
			done
		fi
	fi
done

fullversions_beta=( $( curl -fsSL 'https://download.nextcloud.com/server/prereleases/' |tac|tac| \
	grep -oE 'nextcloud-[[:digit:]]+(\.[[:digit:]]+){2}beta[[:digit:]]+' | \
	grep -oE '[[:digit:]]+(\.[[:digit:]]+){2}beta[[:digit:]]+' | \
	sort -urV ) )
versions_beta=( $( printf '%s\n' "${fullversions_beta[@]}" | cut -d. -f1-2 | sort -urV ) )
for version in "${versions_beta[@]}"; do
	fullversion="$( printf '%s\n' "${fullversions_beta[@]}" | grep -E "^$version" | head -1 )"

	if version_greater_or_equal "$version" "$min_version"; then

		if ! check_rc_released "$fullversion"; then

			for variant in "${variants[@]}"; do

				create_variant "$version-beta" "https:\/\/download.nextcloud.com\/server\/prereleases"
			done
		fi
	fi
done

fullversions_alpha=( $( curl -fsSL 'https://download.nextcloud.com/server/prereleases/' |tac|tac| \
	grep -oE 'nextcloud-[[:digit:]]+(\.[[:digit:]]+){2}alpha[[:digit:]]+' | \
	grep -oE '[[:digit:]]+(\.[[:digit:]]+){2}alpha[[:digit:]]+' | \
	sort -urV ) )
versions_alpha=( $( printf '%s\n' "${fullversions_alpha[@]}" | cut -d. -f1-2 | sort -urV ) )
for version in "${versions_alpha[@]}"; do
	fullversion="$( printf '%s\n' "${fullversions_alpha[@]}" | grep -E "^$version" | head -1 )"

	if version_greater_or_equal "$version" "$min_version"; then

		if ! check_beta_released "$fullversion"; then

			for variant in "${variants[@]}"; do

				create_variant "$version-alpha" "https:\/\/download.nextcloud.com\/server\/prereleases"
			done
		fi
	fi
done

# remove everything after '- stage: test images'
travis="$(awk '!p; /- stage: test images/ {p=1}' .travis.yml)"
echo "$travis" > .travis.yml

# replace the fist '-' with ' '
travisEnv="$(echo "$travisEnv" | sed '0,/-/{s/-/ /}')"
printf "$travisEnv" >> .travis.yml
