#!/bin/bash

set -Eeuo pipefail

if [[ "x${CI:-}" = "xtrue" ]]; then
    # we need ronn to generate the manpages
    sudo apt install -y ronn
fi

./autogen.sh
./configure --disable-silent-rules
make dist-xz

version="$(
    find \
        . \
        -type f \
        -name blogc-\*.tar.xz \
    | head -n 1 \
    | rev \
    | cut -d/ -f1 \
    | rev \
    | sed \
        -e 's/^blogc-//' \
        -e 's/\.tar\.xz$//'
)"

dir="${1:-.}"
echo "${version}" > "${dir}/VERSION"
mv blogc-*.tar.xz "${dir}/blogc_${version}.orig.tar.xz"
