#!/bin/bash
set -e

IMAGE_NAME=hstreamio/haskell-rocksdb
RELEASES_FILE=releases.txt
BUILD_JOBS=${BUILD_JOBS:-4}
IS_PUSH=${IS_PUSH:-false}

try_pull() {
    echo "> Try pull $1, ignore results..."
    docker pull $1 || true
}

build() {
    echo "> Build $IMAGE_NAME:$3 from ./dockerfiles/$2, with GHC=$1"
    docker build ./dockerfiles --file "./dockerfiles/$2" --build-arg GHC="$1" --tag "$IMAGE_NAME:$3"
}

maybe_push() {
    if [ "$IS_PUSH" = true ]; then
        echo "> Push $IMAGE_NAME:$1..."
        docker push "$IMAGE_NAME:$1"
    fi
}

main() {
    while IFS=' ' read -ra line; do
        ghc_ver="${line[0]}"
        IFS=':' read -ra image_tags < <(echo "${line[1]}")
        dockerfile="${line[2]}"

        try_pull "$IMAGE_NAME:${image_tags[0]}"
        build "$ghc_ver" "$dockerfile" "${image_tags[0]}"
        maybe_push "${image_tags[0]}"

        for t in ${image_tags[@]:1}; do
            echo "> tag ${image_tags[0]} ${t}"
            docker tag "$IMAGE_NAME:${image_tags[0]}" "$IMAGE_NAME:${t}"
            maybe_push "${t}"
        done
    done < $RELEASES_FILE
}

main
