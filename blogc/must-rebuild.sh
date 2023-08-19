#!/bin/bash

set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
    echo "error: Invalid number of arguments" > /dev/stderr
    exit 2
fi

dir="$(dirname "${0}")"

version="$(
    curl \
        --silent \
        --include \
        https://github.com/blogc/blogc/releases/latest \
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

cd "${1}/blogc/pool/main/b/blogc"

for v in $(find . -iname "blogc_*${2}_*.deb" | cut -d_ -f2 | cut -d~ -f1); do
    if [[ "x${v}" = "x${deb_version}" ]]; then
        exit 1
    fi
done
