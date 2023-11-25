#!/bin/bash

set -Eeuo pipefail

function die() {
    echo "error:" ${@} > /dev/stderr
    exit 1
}

if [[ $# -ne 2 ]]; then
    die "invalid number of arguments"
fi

source="$(realpath "${1}")"
repos="$(realpath "${2}")"

asrc="$(find "${source}" -name \*.orig.tar.\* | head -n 1)"
src="$(basename "${asrc}")"
if [[ -z "${src}" ]]; then
    die "No source found!"
fi

# if source already exists in repo, reuse it!
asrcrepo="$(find "${repos}" -name "${src}" | head -n 1)"
srcrepo="$(basename "${asrcrepo}")"
if [[ -n "${srcrepo}" ]]; then
    echo ">>> reusing existing source!"
    rm "${asrc}"
    cp -v "${asrcrepo}" "${asrc}"
fi
