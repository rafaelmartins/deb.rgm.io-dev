#!/bin/bash

NUM_ARGS=1
DEPENDENCIES="ronn"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/../.scripts"
source "${SCRIPT_DIR}/utils.sh"

OUTPUT_DIR="$(realpath "${1:-.}")"

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

echo "${version}" > "${OUTPUT_DIR}/VERSION"
mv blogc-*.tar.xz "${OUTPUT_DIR}/blogc_${version}.orig.tar.xz"
