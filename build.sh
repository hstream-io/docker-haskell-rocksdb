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
    if [ "$1" == "buster.rocksdb" ]; then
        echo "> Build $IMAGE_NAME:$2 from ./dockerfiles/$1, with ROCKSDB_VERSION="$3""
        docker build ./dockerfiles --file "./dockerfiles/$1" --build-arg ROCKSDB_VERSION="$3" --tag "$IMAGE_NAME:$2"
        echo "> Check if rocksdb has installed..."
        docker run --rm -v $(pwd):/srv -w /srv "$IMAGE_NAME:$2" bash -c 'apt-get update && apt-get install -y gcc && gcc tests/c_simple_example.c -lrocksdb -ldl -o /tmp/c_simple_example && /tmp/c_simple_example'
    elif [ "$1" == "buster.haskell" ]; then
        echo "> Build $IMAGE_NAME:$2 from ./dockerfiles/$1, with GHC=$3"
        docker build ./dockerfiles --file "./dockerfiles/$1" --build-arg GHC="$3" --tag "$IMAGE_NAME:$2"
        echo "> Check if ghc has installed..."
        docker run --rm "$IMAGE_NAME:$2" bash -c '[ `ghc --numeric-version` == '"$3"' ]'
    fi
}

maybe_push() {
    if [ "$IS_PUSH" = true ]; then
        echo "> Push $IMAGE_NAME:$1..."
        docker push "$IMAGE_NAME:$1"
    fi
}

main() {
    while IFS=' ' read -ra line; do
        dockerfile="${line[0]}"
        IFS=':' read -ra image_tags < <(echo "${line[1]}")
        try_pull "$IMAGE_NAME:${image_tags[0]}"
        build "$dockerfile" "${image_tags[0]}" "${line[2]}"
        maybe_push "${image_tags[0]}"

        for t in ${image_tags[@]:1}; do
            echo "> tag ${image_tags[0]} ${t}"
            docker tag "$IMAGE_NAME:${image_tags[0]}" "$IMAGE_NAME:${t}"
            maybe_push "${t}"
        done
    done < $RELEASES_FILE
}

main
