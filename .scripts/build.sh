#!/bin/bash

set -x

export DEBEMAIL="rafael+deb@rafaelmartins.eng.br"
export DEBFULLNAME="Automatic Builder (github-actions)"

NUM_ARGS=5
DEPENDENCIES="devscripts equivs"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

MAIN_DIR="$(realpath "${1}")"
ORIG_DIR="$(realpath "${2}")"
OUTPUT_DIR="$(realpath "${3}")"
REPO_NAME="${4}"
DISTRO="${5}"

CODENAME="$(echo "${5}" | cut -d_ -f2)"

IMAGE="$("${SCRIPT_DIR}/distro-docker-image.sh" "${CODENAME}")"

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "${tmpdir}"' EXIT

mkdir -p "${tmpdir}"/build{,deps}

# FIXME: this could be moved to source phase
pushd "${tmpdir}/builddeps" > /dev/null
mk-build-deps "${MAIN_DIR}/${REPO_NAME%%-snapshot}/debian/control"
popd > /dev/null

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
    "${MAIN_DIR}/${REPO_NAME%%-snapshot}/debian" \
    .

if ! dch \
    --distribution "${CODENAME}" \
    --newversion "${version}-1~$("${SCRIPT_DIR}/distro-version-suffix.sh" "${CODENAME}")" \
    "Automated build for ${CODENAME}"
then
    exit 0
fi

popd > /dev/null

docker run \
    --pull=always \
    --rm \
    --init \
    --env DEB_BUILD_OPTIONS=noddebs \
    --env DEBIAN_FRONTEND=noninteractive \
    --volume "${tmpdir}/build:/build" \
    --volume "${tmpdir}/builddeps:/builddeps" \
    --workdir "/build/$(basename "${builddir}")" \
    "${IMAGE}" \
    bash \
        -c "\
            apt update \
                && apt install -y --no-install-recommends /builddeps/*.deb \
                && dpkg-buildpackage -uc -us -sa; \
            chown -R $(id -u):$(id -g) /build \
        "

mkdir -p "${OUTPUT_DIR}/${REPO_NAME}_${CODENAME}"

find \
    "${tmpdir}/build" \
    -maxdepth 1 \
    -type f \
    -exec cp -- "{}" "${OUTPUT_DIR}/${REPO_NAME}_${CODENAME}/" \;
