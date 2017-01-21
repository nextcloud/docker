#!/bin/bash
set -e

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

Maintainers: Nextcloud <docker@nextcloud.com> (@nextcloud),
             Pierre Ozoux <pierre@ozoux.net> (@pierreozoux)
GitRepo: https://github.com/nextcloud/docker.git
EOH

# prints "$2$1$3$1...$N"
join() {
	local sep="$1"; shift
	local out; printf -v out "${sep//%/%%}%s" "$@"
	echo "${out#$sep}"
}

latest=$(curl -sSL 'https://nextcloud.com/changelog/' |tac|tac \
	   | grep -o "\(Version\|Release\)\s\+[[:digit:]]\+\(.[[:digit:]]\+\)\+" \
	   | awk '{ print $2 }' \
	   | sort -uV \
	   | tail -1)

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
			GitCommit: $commit
			Directory: $version/$variant
		EOE
	done
done
