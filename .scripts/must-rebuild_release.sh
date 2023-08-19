#!/bin/bash

set -Eeuo pipefail

if [[ $# -ne 5 ]]; then
    echo "error: Invalid number of arguments" > /dev/stderr
    exit 2
fi

dir="${1}"
reponame="$(basename "${dir}")"
ghowner="${2}"
ghrepo="${3}"
reposdir="${4}"
distribution="${5}"

version="$(
    curl \
        --silent \
        --include \
        "https://github.com/${ghowner}/${ghrepo}/releases/latest" \
    | sed -n '/^location:/ s,.*/v\([\.a-z0-9-]*\)[^/]*$,\1,p'
)"

deb_version="$(
    grep \
        "(${version}" \
        "${dir}/debian/changelog" \
    | cut -d\( -f2 \
    | cut -d\) -f1 \
    | cut -d~ -f1 \
    | head -n 1
)"

cd "${reposdir}/${reponame}/pool/main/"*"/${ghrepo}"

for v in $(find . -iname "${ghrepo}_*${distribution}_*.deb" | cut -d_ -f2 | cut -d~ -f1); do
    if [[ "x${v}" = "x${deb_version}" ]]; then
        exit 1
    fi
done
