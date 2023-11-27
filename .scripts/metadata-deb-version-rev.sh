#!/bin/bash

NUM_ARGS=3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

DEB_DIR="$(realpath "${1}")"
REPO_NAME="${2}"
CODENAME="${3}"

if [[ ! -d "${DEB_DIR}/${REPO_NAME}/${CODENAME}" ]]; then
    exit 1
fi

pushd "${DEB_DIR}/${REPO_NAME}/${CODENAME}" > /dev/null

ls \
    -1 \
    "${REPO_NAME%%-snapshot}_"*"${CODENAME}"*".deb" \
2> /dev/null \
| cut -d_ -f2 \
| cut -d~ -f1 \
| sort -u \
| head -n1

popd > /dev/null
