#!/bin/bash
set -e

IMAGE_NAME=hstreamio/haskell-rocksdb
RELEASES_FILE=releases.txt
IS_PUSH={$IS_PUSH:-false}

main() {
    while IFS=' ' read -ra line; do
        tag="${line[0]}"
        docker_dir="${line[2]}"
        docker_file="${line[3]}"
        echo "Build $IMAGE_NAME:${tag} from ${docker_dir}/${docker_file}..."
        docker build "./${docker_dir}" --file "${docker_dir}/${docker_file}" --tag "$IMAGE_NAME:${tag}"
        if [ "$IS_PUSH" = true ]; then
            echo "Push $IMAGE_NAME:${tag}..."
            docker push "$IMAGE_NAME:${tag}"
        fi

        IFS=':' read -ra alias_tags < <(echo "${line[1]}")
        for t in ${alias_tags[@]}; do
            echo "Tag ${tag} to ${t}"
            docker tag "$IMAGE_NAME:${tag}" "$IMAGE_NAME:${t}"
            if [ "$IS_PUSH" = true ]; then
                echo "Push "$IMAGE_NAME:${t}"..."
                docker push "$IMAGE_NAME:${t}"
            fi
        done
    done < $RELEASES_FILE
}

main
