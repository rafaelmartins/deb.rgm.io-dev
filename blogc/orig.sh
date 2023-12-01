#!/bin/bash

NUM_ARGS=1
DEPENDENCIES="ronn"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/../.scripts"
source "${SCRIPT_DIR}/utils.sh"

OUTPUT_DIR="$(realpath "${1:-.}")"

./autogen.sh
./configure
make dist-xz

mv \
    blogc-*.tar.xz \
    "$(
        echo blogc-*.tar.xz \
        | sed \
            -e 's/blogc-/blogc_/' \
            -e 's/\.tar\./.orig.tar./'
    )"
