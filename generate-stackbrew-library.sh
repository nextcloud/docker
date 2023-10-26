#!/usr/bin/env bash
set -Eeuo pipefail

stable_channel='27.1.3'

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Get the most recent commit which modified any of "$@".
fileCommit() {
	commit="$(git log -1 --format='format:%H' HEAD -- "$@")"
	if [ -z "$commit" ]; then
		# return some valid sha1 hash to make bashbrew happy
		echo '0000000000000000000000000000000000000000'
	else
		echo "$commit"
	fi
}

# Get the most recent commit which modified "$1/Dockerfile" or any file that
# the Dockerfile copies into the rootfs (with COPY).
dockerfileCommit() {
	local dir="$1"; shift
	(
		cd "$dir";
		fileCommit Dockerfile \
			$(awk '
				toupper($1) == "COPY" {
					for (i = 2; i < NF; i++)
							print $i;
				}
			' Dockerfile)
	)
}

getArches() {
	local repo="$1"; shift
	local officialImagesUrl='https://github.com/docker-library/official-images/raw/master/library/'

	eval "declare -g -A parentRepoToArches=( $(
		find -maxdepth 3 -name 'Dockerfile' -exec awk '
				toupper($1) == "FROM" && $2 !~ /^('"$repo"'|scratch|microsoft\/[^:]+)(:|$)/ {
					print "'"$officialImagesUrl"'" $2
				}
			' '{}' + \
			| sort -u \
			| xargs bashbrew cat --format '[{{ .RepoName }}:{{ .TagName }}]="{{ join " " .TagEntry.Architectures }}"'
	) )"
}
getArches 'nextcloud'

# Header.
cat <<-EOH
# This file is generated via https://github.com/nextcloud/docker/blob/$(fileCommit "$self")/$self

Maintainers: Nextcloud <docker@nextcloud.com> (@nextcloud)
GitRepo: https://github.com/nextcloud/docker.git
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

latest=$( cat latest.txt )

# Generate each of the tags.
versions=( */ )
versions=( "${versions[@]%/}" )
for version in "${versions[@]}"; do
	variants=( $version/*/ )
	variants=( $(for variant in "${variants[@]%/}"; do
		echo "$(basename "$variant")"
	done) )
	for variant in "${variants[@]}"; do
		commit="$(dockerfileCommit "$version/$variant")"
		fullversion_with_extension="$( awk '$1 == "ENV" && $2 == "NEXTCLOUD_VERSION" { print $3; exit }' "$version/$variant/Dockerfile" )"
		fullversion="$( echo "$fullversion_with_extension" | grep -oE '[[:digit:]]+(\.[[:digit:]]+){2}')"

		versionAliases=( )
		versionPostfix=""
		if [ "$fullversion_with_extension" != "$fullversion" ]; then
			versionAliases=( "$fullversion_with_extension" )
			versionPostfix="-$( echo "$fullversion_with_extension" | tr '[:upper:]' '[:lower:]' | grep -oE '(beta|rc|alpha)')"
		fi

		versionAliases+=( "$fullversion$versionPostfix" "${fullversion%.*}$versionPostfix" "${fullversion%.*.*}$versionPostfix" )
		if [ "$fullversion_with_extension" = "$latest" ]; then
			versionAliases+=( "latest" )
		fi

		if [ "$fullversion_with_extension" = "$stable_channel" ]; then
			versionAliases+=( "stable" "production" )
		fi

		variantAliases=( "${versionAliases[@]/%/-$variant}" )
		variantAliases=( "${variantAliases[@]//latest-}" )

		if [ "$variant" = "apache" ]; then
			variantAliases+=( "${versionAliases[@]}" )
		fi

		variantParent="$(awk 'toupper($1) == "FROM" { print $2 }' "$version/$variant/Dockerfile")"
		variantArches="${parentRepoToArches[$variantParent]}"

		cat <<-EOE

			Tags: $(join ', ' "${variantAliases[@]}")
			Architectures: $(join ', ' $variantArches)
			GitCommit: $commit
			Directory: $version/$variant
		EOE
	done
done
