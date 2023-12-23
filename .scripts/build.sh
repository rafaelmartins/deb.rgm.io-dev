#!/bin/bash

NUM_ARGS=7
DEPENDENCIES="devscripts"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ORIG_DIR="$(realpath "${1}")"
NEW_DIR="$(realpath "${2}")"
CHANGELOG_DIR="$(realpath "${3}")"
OUTPUT_DIR="$(realpath "${4}")"
REPO_NAME="${5}"
DISTRO="${6}"
ARCH="${7}"

CODENAME="$(echo "${DISTRO}" | cut -d_ -f2)"

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "${tmpdir}"' EXIT

mkdir -p "${tmpdir}/build"

source="$(basename "$(
    ls \
        -1 \
        "${ORIG_DIR}/${REPO_NAME}/"*.orig.* \
    2> /dev/null \
    | head -n1 \
    || true
)")"

tar \
    --extract \
    --verbose \
    --file "${ORIG_DIR}/${REPO_NAME}/${source}" \
    --directory "${tmpdir}/build"

cp \
    "${ORIG_DIR}/${REPO_NAME}/${source}" \
    "${tmpdir}/build/"

builddir="$(
    find \
        "${tmpdir}/build" \
        -maxdepth 1 \
        -type d \
        -iname "${REPO_NAME%%-snapshot}*" \
    | head -n 1
)"

pushd "${builddir}" > /dev/null

cp \
    --recursive \
    "${ROOT_DIR}/${REPO_NAME%%-snapshot}/debian" \
    .

cp \
    "${CHANGELOG_DIR}/${REPO_NAME}/${CODENAME}/changelog" \
    debian/changelog \
&> /dev/null \
|| exit 0

popd > /dev/null

mkdir -p "${OUTPUT_DIR}"

if [[ "${ARCH}" != source ]]; then
    docker run \
        --platform="linux/${ARCH}" \
        --pull=always \
        --rm \
        --init \
        --env DEB_BUILD_OPTIONS=noddebs \
        --env DEBIAN_FRONTEND=noninteractive \
        --volume "${tmpdir}/build:/build" \
        --volume "${NEW_DIR}:/builddeps" \
        --workdir "/build/$(basename "${builddir}")" \
        "$("${SCRIPT_DIR}/distro-docker-image.sh" "${CODENAME}")" \
        bash \
            -c "\
                set -Eeuo pipefail; \
                trap 'chown -R $(id -u):$(id -g) /build' EXIT; \
                apt update \
                    && apt install -y --no-install-recommends /builddeps/*.deb \
                    && dpkg-buildpackage -uc -us -sa; \
            "

    find \
        "${tmpdir}/build" \
        -maxdepth 1 \
        -type f \
        -exec cp -- "{}" "${OUTPUT_DIR}/" \;
else
    pushd "${builddir}" > /dev/null
    dpkg-source --build .
    popd > /dev/null

    find \
        "$(dirname "${builddir}")" \
        -maxdepth 1 \
        -type f \
        -exec cp -- "{}" "${OUTPUT_DIR}/" \;
fi

rm \
    --force \
    "${OUTPUT_DIR}/"*.orig.tar.*
