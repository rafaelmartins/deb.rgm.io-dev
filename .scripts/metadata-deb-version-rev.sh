#!/bin/bash

NUM_ARGS=4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

DEB_DIR="$(realpath "${1}")"
REPO_NAME="${2}"
CODENAME="${3}"
ARCH="${4}"

pushd "${DEB_DIR}/${REPO_NAME}/${CODENAME}" &> /dev/null || exit 0

f=
if [[ "${ARCH}" = source ]]; then
    f="$(ls -1 "${REPO_NAME%%-snapshot}_"*"${CODENAME}.debian.tar."* 2> /dev/null || true)"
else
    f="$(ls -1 "${REPO_NAME%%-snapshot}_"*"${CODENAME}_${ARCH}.deb" 2> /dev/null || true)"
fi

if [[ -n "${f}" ]]; then
    echo "${f}" \
    | cut -d_ -f2 \
    | cut -d~ -f1 \
    | sort -u \
    | head -n1
fi

popd > /dev/null
