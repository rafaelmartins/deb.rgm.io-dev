#!/bin/bash

export DEBEMAIL="rafael+deb@rafaelmartins.eng.br"
export DEBFULLNAME="Automatic Builder (github-actions)"

NUM_ARGS=5
DEPENDENCIES="devscripts"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

OUTPUT_DIR="$(realpath "${1}")"
DEB_DIR="$(realpath "${2}")"
REPO_NAME="${3}"
DISTRO="${4}"
VERSION_REV="${5}"

CODENAME="$(echo "${DISTRO}" | cut -d_ -f2)"
VER="$(echo "${DISTRO}" | cut -d_ -f3)"

mkdir -p "${OUTPUT_DIR}/${REPO_NAME}/${CODENAME}"

debianfile="$(
    ls \
        -1 \
        "${DEB_DIR}/${REPO_NAME}/${CODENAME}/${REPO_NAME%%-snapshot}_${VERSION_REV}~${VER}${CODENAME}.debian.tar."* \
    2> /dev/null \
    | head \
        -n 1 \
    || true
)"

if [[ -f "${debianfile}" ]]; then
    echo "reusing"

    tmpdir="$(mktemp -d)"
    trap 'rm -rf -- "${tmpdir}"' EXIT

    tar \
        --extract \
        --strip-components 1 \
        --file "${debianfile}" \
        --directory "${OUTPUT_DIR}/${REPO_NAME}/${CODENAME}" \
        debian/changelog

    exit 0
fi

cp \
    "${ROOT_DIR}/${REPO_NAME%%-snapshot}/debian/changelog" \
    "${OUTPUT_DIR}/${REPO_NAME}/${CODENAME}/"

dch \
    --force-distribution \
    --changelog "${OUTPUT_DIR}/${REPO_NAME}/${CODENAME}/changelog" \
    --distribution "${CODENAME}" \
    --newversion "${VERSION_REV}~${VER}${CODENAME}" \
    "Automated build for ${CODENAME}"
