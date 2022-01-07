#!/usr/bin/env bash
set -e

image="$1"

cd .examples/dockerfiles

dirs=( */ )
dirs=( "${dirs[@]%/}" )
for dir in "${dirs[@]}"; do
    if [ -d "$dir/$VARIANT" ]; then
        (
            cd "$dir/$VARIANT"
            sed -ri -e 's/^FROM .*/FROM '"$image"'/g' 'Dockerfile'
            docker build -t "$image-$dir" .
        )
    fi
done
