#!/bin/bash

set -x

export DEBEMAIL="rafael+deb@rafaelmartins.eng.br"
export DEBFULLNAME="Automatic Builder (github-actions)"

NUM_ARGS=6
DEPENDENCIES="devscripts"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ORIG_DIR="$(realpath "${1}")"
NEW_DIR="$(realpath "${2}")"
OUTPUT_DIR="$(realpath "${3}")"
REPO_NAME="${4}"
DISTRO="${5}"
ARCH="${6}"

CODENAME="$(echo "${DISTRO}" | cut -d_ -f2)"

IMAGE="$("${SCRIPT_DIR}/distro-docker-image.sh" "${CODENAME}")"

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "${tmpdir}"' EXIT

mkdir -p "${tmpdir}/build"

source="$(basename "$(
    ls \
        -1 \
        "${ORIG_DIR}/${REPO_NAME}/"*.orig.* \
    | head -n1
)")"

version="$(
    echo "${source}" \
    | sed 's/\.orig\..*$//' \
    | cut -d_ -f2
)"

revision="$(
    "${SCRIPT_DIR}/metadata-changelog-version-rev.sh" \
        "${REPO_NAME}" \
    | rev \
    | cut -d- -f1 \
    | rev
)"
if [[ -z "${revision}" ]]; then
    revision=1
fi

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

suffix="$("${SCRIPT_DIR}/distro-version-suffix.sh" "${CODENAME}")"

cp \
    --recursive \
    "${ROOT_DIR}/${REPO_NAME%%-snapshot}/debian" \
    .

if ! dch \
    --force-distribution \
    --distribution "${CODENAME}" \
    --newversion "${version}-${revision}~${suffix}" \
    "Automated build for ${CODENAME}"
then
    exit 0
fi

popd > /dev/null

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
    "${IMAGE}" \
    bash \
        -c "\
            set -Eeuo pipefail; \
            trap 'chown -R $(id -u):$(id -g) /build' EXIT; \
            apt update \
                && apt install -y --no-install-recommends /builddeps/*.deb \
                && dpkg-buildpackage -uc -us -sa; \
        "

mkdir -p "${OUTPUT_DIR}"

find \
    "${tmpdir}/build" \
    -maxdepth 1 \
    -type f \
    -exec cp -- "{}" "${OUTPUT_DIR}/" \;
