#!/bin/bash
set -e

IMAGE_NAME=hstreamdb/haskell-rocksdb
RELEASES_FILE=releases.txt
BUILD_JOBS=${BUILD_JOBS:-4}
IS_PUSH=${IS_PUSH:-false}
CACHE_DIR=${CACHE_DIR:-""}

build() {
    dockerfile="./dockerfiles/$1"
    image_tag=$2

    # build rocksdb with debian buster
    if [ "$1" == "buster.rocksdb" ]; then
        rocksdb_version=$3
        echo "> Build $IMAGE_NAME:$image_tag from $dockerfile, with ROCKSDB_VERSION=$rocksdb_version"
        docker build ./dockerfiles --file $dockerfile --build-arg ROCKSDB_VERSION=$rocksdb_version --tag "$IMAGE_NAME:$image_tag"
        echo "> Check if rocksdb has installed..."
        docker run --rm -v $(pwd):/srv -w /srv "$IMAGE_NAME:$2" bash -c 'apt-get update && apt-get install -y gcc && gcc tests/c_simple_example.c -lrocksdb -ldl -o /tmp/c_simple_example && /tmp/c_simple_example'

    # install haskell build tools
    elif [ "$1" == "buster.haskell" ]; then
        ghc_version=$3
        echo "> Build $IMAGE_NAME:$image_tag from $dockerfile, with GHC=$ghc_version"
        docker build ./dockerfiles --file $dockerfile --build-arg GHC=$ghc_version --tag "$IMAGE_NAME:$image_tag"
        echo "> Check if ghc has installed..."
        docker run --rm "$IMAGE_NAME:$image_tag" bash -c '[ `ghc --numeric-version` == '"$ghc_version"' ]'
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
        pkg_version="${line[2]}"

        image_tag="${image_tags[0]}"
        image_cache="${CACHE_DIR}/$(echo ${IMAGE_NAME}_${image_tag} | sed 's#/#_#g')"
        test -f $image_cache && \
            echo "-> Loading image cache from $image_cache" && \
            docker load -i $image_cache

        build "$dockerfile" "$image_tag" "$pkg_version"
        maybe_push "$image_tag"

        test "$CACHE_DIR" && \
            mkdir -p "$CACHE_DIR" && \
            echo "-> Saving image cache to $image_cache" && \
            docker save -o $image_cache $IMAGE_NAME:$image_tag

        # alias
        for t in ${image_tags[@]:1}; do
            echo "> tag ${image_tags[0]} ${t}"
            docker tag "$IMAGE_NAME:${image_tags[0]}" "$IMAGE_NAME:${t}"
            maybe_push "${t}"
        done
    done < $RELEASES_FILE
}

main
