#!/bin/bash
set -eo pipefail

declare -A cmd=(
	[apache]='apache2-foreground'
	[fpm]='php-fpm'
)

# version_greater_or_equal A B returns whether A >= B
function version_greater_or_equal() {
	[[ "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1" || "$1" == "$2" ]];
}

latests=( $( curl -fsSL 'https://download.nextcloud.com/server/releases/' |tac|tac| \
	grep -oE 'nextcloud-[[:digit:]]+(.[[:digit:]]+)+' | \
	grep -oE '[[:digit:]]+(.[[:digit:]]+)+' | \
	sort -urV ) )

find . -maxdepth 1 -type d -regextype sed -regex '\./[[:digit:]]\+\.[[:digit:]]\+' -exec rm -r '{}' \;

travisEnv=
for latest in "${latests[@]}"; do
	version=$(echo "$latest" | cut -d. -f1-2)

	if [ -d "$version" ]; then
		continue
	fi

	# Only add versions >= 11
	if version_greater_or_equal "$version" "11.0"; then

		for variant in apache fpm; do
			# Create the version+variant directory with a Dockerfile.
			mkdir -p "$version/$variant"

			template="Dockerfile.template"
			cp "$template" "$version/$variant/Dockerfile"

			echo "updating $latest [$version] $variant"

			# Replace the variables.
			sed -ri -e '
				s/%%VARIANT%%/'"$variant"'/g;
				s/%%VERSION%%/'"$latest"'/g;
				s/%%CMD%%/'"${cmd[$variant]}"'/g;
			' "$version/$variant/Dockerfile"

			# Copy the docker-entrypoint.
			cp docker-entrypoint.sh "$version/$variant/docker-entrypoint.sh"

			# Copy the config directory
			cp -rT .config "$version/$variant/config"

			# Remove Apache commands and configs if we're not an Apache variant.
			if [ "$variant" != "apache" ]; then
				sed -ri -e '/a2enmod/d' "$version/$variant/Dockerfile"
				rm "$version/$variant/config/apache-pretty-urls.config.php"
			fi

			for arch in i386 amd64; do
				travisEnv='\n    - env: VERSION='"$version"' VARIANT='"$variant"' ARCH='"$arch$travisEnv"
			done
		done
	fi
done

# replace the fist '-' with ' '
travisEnv="$(echo "$travisEnv" | sed '0,/-/{s/-/ /}')"

# update .travis.yml
travis="$(awk -v 'RS=\n\n' '$1 == "-" && $2 == "stage:" && $3 == "test" && $4 == "images" { $0 = "    - stage: test images'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis"  > .travis.yml
