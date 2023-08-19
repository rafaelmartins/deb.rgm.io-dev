#!/bin/bash

set -Eeuo pipefail

if [[ $# -ne 5 ]]; then
    echo "error: Invalid number of arguments" > /dev/stderr
    exit 2
fi

reponame="$(basename "${1}")"
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

version_hash="$(
    git \
        ls-remote \
        https://github.com/${ghowner}/${ghrepo}.git \
        HEAD
)"
version_hash=${version_hash:0:4}

cd "${reposdir}/${reponame}/pool/main/"*"/${ghrepo}"

for v in $(find . -iname "${ghrepo}_${version}.*-${version_hash}-*${distribution}_*.deb" | cut -d_ -f2 | cut -d~ -f1); do
    exit 1
done
