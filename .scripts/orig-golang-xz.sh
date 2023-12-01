#!/bin/bash

NUM_ARGS=3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

OUTPUT_DIR="$(realpath "${1}")"
NAME="${2}"
VERSION="${3}"

git archive \
    --format=tar \
    --prefix="${NAME}-${VERSION}/" \
    HEAD \
| xz \
> "${OUTPUT_DIR}/${NAME}_${VERSION}.orig.tar.xz"
