#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

OUTPUT_DIR="$(realpath "${1}")"
REPO_NAME="${2}"

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "${tmpdir}"' EXIT

for platform in linux/amd64 linux/arm64; do
    dir="${tmpdir}/$(basename "${platform}")"
    mkdir -p "${dir}"

    docker run \
        --platform="${platform}" \
        --pull=always \
        --rm \
        --init \
        --volume "${ROOT_DIR}/${REPO_NAME%%-snapshot}:/src" \
        --volume "${dir}:/builddeps" \
        --workdir /builddeps \
        debian:sid \
        bash \
            -c "\
                set -Eeuo pipefail; \
                trap 'chown -R $(id -u):$(id -g) /builddeps' EXIT; \
                apt update \
                    && apt install -y --no-install-recommends devscripts equivs \
                    && mk-build-deps /src/debian/control; \
            "
done

mkdir -p "${OUTPUT_DIR}"
cp -rv "${tmpdir}"/* "${OUTPUT_DIR}/"
