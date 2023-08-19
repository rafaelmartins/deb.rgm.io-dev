#!/bin/bash

set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
    echo "error: Invalid number of arguments" > /dev/stderr
    exit 2
fi

version="$(
    curl \
        --silent \
        --include \
        https://github.com/blogc/blogc/releases/latest \
    | sed -n '/^location:/ s,.*/v\([\.a-z0-9-]*\)[^/]*$,\1,p'
)"

version_hash="$(
    git \
        ls-remote \
        https://github.com/blogc/blogc.git \
        HEAD
)"
version_hash=${version_hash:0:4}

cd "${1}/blogc-snapshot/pool/main/b/blogc"

for v in $(find . -iname "blogc_${version}.*-${version_hash}-*${2}_*.deb" | cut -d_ -f2 | cut -d~ -f1); do
    exit 1
done
