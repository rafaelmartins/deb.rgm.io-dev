#!/bin/bash

NUM_ARGS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/../.scripts"
source "${SCRIPT_DIR}/utils.sh"

OUTPUT_DIR="$(realpath "${1}")"

version="$(
    git describe \
        --abbrev=4 \
        HEAD \
    | sed \
        -e 's/^v//' \
        -e 's/-/./' \
        -e 's/-g/-/'
)"

git archive \
    --format=tar \
    --prefix="filebin-${version}/" \
    HEAD \
| xz \
> "${OUTPUT_DIR}/filebin_${version}.orig.tar.xz"
