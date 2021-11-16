#!/usr/bin/env bash
set -eo pipefail

declare -A php_version=(
	[default]='8.0'
	[21]='7.4'
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
	[apache]='\nRUN a2enmod headers rewrite remoteip ;\\\n    {\\\n     echo RemoteIPHeader X-Real-IP ;\\\n     echo RemoteIPTrustedProxy 10.0.0.0/8 ;\\\n     echo RemoteIPTrustedProxy 172.16.0.0/12 ;\\\n     echo RemoteIPTrustedProxy 192.168.0.0/16 ;\\\n    } > /etc/apache2/conf-available/remoteip.conf;\\\n    a2enconf remoteip'
	[fpm]=''
	[fpm-alpine]=''
)

declare -A crontab_int=(
	[default]='5'
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
	[redis]="$redis_version"
	[imagick]="$imagick_version"
)

variants=(
	apache
	fpm
	fpm-alpine
)

min_version='21'

# version_greater_or_equal A B returns whether A >= B
function version_greater_or_equal() {
	[[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || "$1" == "$2" ]];
}

function create_variant() {
	dir="$1/$variant"
	phpVersion=${php_version[$version]-${php_version[default]}}
	crontabInt=${crontab_int[$version]-${crontab_int[default]}}

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
		s/%%CRONTAB_INT%%/'"$crontabInt"'/g;
	' "$dir/Dockerfile"

	case "$phpVersion" in
		7.4|8.0 )
			sed -ri -e '
				\@docker-php-ext-configure gmp --with-gmp@d;
				\@/usr/include/gmp.h@d;
				' "$dir/Dockerfile"
			;;
		7.3 )
			sed -ri -e '
				s@gd --with-freetype --with-jpeg --with-webp@gd --with-freetype-dir=/usr --with-png-dir=/usr --with-jpeg-dir=/usr --with-webp-dir=/usr@g;
				' "$dir/Dockerfile"
			;;
	esac

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
}

curl -fsSL 'https://download.nextcloud.com/server/releases/' |tac|tac| \
	grep -oE 'nextcloud-[[:digit:]]+(\.[[:digit:]]+){2}' | \
	grep -oE '[[:digit:]]+(\.[[:digit:]]+){2}' | \
	sort -uV | \
	tail -1 > latest.txt

find . -maxdepth 1 -type d -regextype sed -regex '\./[[:digit:]]\+\.[[:digit:]]\+\(-rc\|-beta\|-alpha\)\?' -exec rm -r '{}' \;

fullversions=( $( curl -fsSL 'https://download.nextcloud.com/server/releases/' |tac|tac| \
	grep -oE 'nextcloud-[[:digit:]]+(\.[[:digit:]]+){2}' | \
	grep -oE '[[:digit:]]+(\.[[:digit:]]+){2}' | \
	sort -urV ) )
versions=( $( printf '%s\n' "${fullversions[@]}" | cut -d. -f1 | sort -urV ) )
for version in "${versions[@]}"; do
	fullversion="$( printf '%s\n' "${fullversions[@]}" | grep -E "^$version" | head -1 )"

	if version_greater_or_equal "$version" "$min_version"; then

		for variant in "${variants[@]}"; do

			create_variant "$version" "https:\/\/download.nextcloud.com\/server\/releases"
		done
	fi
done
