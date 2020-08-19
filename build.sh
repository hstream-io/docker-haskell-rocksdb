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
    echo "> Build $IMAGE_NAME:$1 from $2/$3..."
    docker build "./$2" --file "$2/$3" --tag "$IMAGE_NAME:$1"
}

maybe_push() {
    if [ "$IS_PUSH" = true ]; then
        echo "> Push $IMAGE_NAME:$1..."
        docker push "$IMAGE_NAME:$1"
    fi
}

main() {
    while IFS=' ' read -ra line; do
        tag="${line[0]}"
        docker_dir="${line[2]}"
        docker_file="${line[3]}"
        IFS=':' read -ra alias_tags < <(echo "${line[1]}")

        try_pull "$IMAGE_NAME:${tag}"
        build "$tag" "$docker_dir" "$docker_file"
        maybe_push "$tag"

        for t in ${alias_tags[@]}; do
            echo "> Tag ${tag} to ${t}"
            docker tag "$IMAGE_NAME:${tag}" "$IMAGE_NAME:${t}"
            maybe_push "${t}"
        done
    done < $RELEASES_FILE
}

main
