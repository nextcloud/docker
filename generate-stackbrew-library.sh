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

		cat <<-EOE

			Tags: $(join ', ' "${variantAliases[@]}")
			Architectures: amd64, arm32v5, arm32v7, arm64v8, i386, ppc64le, s390x
			GitCommit: $commit
			Directory: $version/$variant
		EOE
	done
done
