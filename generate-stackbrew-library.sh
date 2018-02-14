#!/bin/bash
set -Eeuo pipefail

self="$(basename "$BASH_SOURCE")"
cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

# Get the most recent commit which modified any of "$@".
fileCommit() {
	git log -1 --format='format:%H' HEAD -- "$@"
}

# Get the most recent commit which modified "$1/Dockerfile" or any file that
# the Dockerfile copies into the rootfs (with COPY).
dockerfileCommit() {
	local dir="$1"; shift
	(
		cd "$dir";
		fileCommit Dockerfile \
			$(git show HEAD:./Dockerfile | awk '
				toupper($1) == "COPY" {
					for (i = 2; i < NF; i++)
							print $i;
				}
			')
	)
}

getArches() {
	local repo="$1"; shift
	local officialImagesUrl='https://github.com/docker-library/official-images/raw/master/library/'

	eval "declare -g -A parentRepoToArches=( $(
		find -name 'Dockerfile' -exec awk '
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

latest=$( curl -fsSL 'https://download.nextcloud.com/server/releases/' |tac|tac| \
	grep -oE 'nextcloud-[[:digit:]]+(.[[:digit:]]+)+' | \
	grep -oE '[[:digit:]]+(.[[:digit:]]+)+' | \
	sort -uV | \
	tail -1 )

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
		fullversion="$(git show "$commit":"$version/$variant/Dockerfile" | awk '$1 == "ENV" && $2 == "NEXTCLOUD_VERSION" { print $3; exit }')"

		versionAliases=( "$fullversion" "${fullversion%.*}" "${fullversion%.*.*}" )
		if [ "$fullversion" = "$latest" ]; then
			versionAliases+=( "latest" )
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
