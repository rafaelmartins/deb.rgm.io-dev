#!/bin/bash

set -x

export DEBEMAIL="rafael+deb@rafaelmartins.eng.br"
export DEBFULLNAME="Automatic Builder (github-actions)"

NUM_ARGS=4
DEPENDENCIES="devscripts"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ORIG_DIR="$(realpath "${1}")"
OUTPUT_DIR="$(realpath "${2}")"
REPO_NAME="${3}"
DISTRO="${4}"

CODENAME="$(echo "${4}" | cut -d_ -f2)"

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

for platform in linux/amd64 linux/arm64 linux/arm/v7; do
    rm -rf "${tmpdir}/builddeps"
    mkdir -p "${tmpdir}/builddeps"

    docker run \
        --platform="${platform}" \
        --pull=always \
        --rm \
        --init \
        --volume "${ROOT_DIR}/${REPO_NAME%%-snapshot}:/src" \
        --volume "${tmpdir}/builddeps:/builddeps" \
        --workdir /builddeps \
        "${IMAGE}" \
        bash \
            -c "\
                set -Eeuo pipefail; \
                trap 'chown -R $(id -u):$(id -g) /builddeps' EXIT; \
                apt update \
                    && apt install -y devtools equivs \
                    && mk-build-deps /src/debian/control; \
            "

    docker run \
        --platform="${platform}" \
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
                set -Eeuo pipefail; \
                trap 'chown -R $(id -u):$(id -g) /build' EXIT; \
                apt update \
                    && apt install -y --no-install-recommends /builddeps/*.deb \
                    && dpkg-buildpackage -uc -us -sa; \
            "
done
mkdir -p "${OUTPUT_DIR}"

find \
    "${tmpdir}/build" \
    -maxdepth 1 \
    -type f \
    -exec cp -- "{}" "${OUTPUT_DIR}/" \;
