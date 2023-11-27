#!/bin/bash

NUM_ARGS=2
DEPENDENCIES="ronn"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/../.scripts"
source "${SCRIPT_DIR}/utils.sh"

./autogen.sh
./configure
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
