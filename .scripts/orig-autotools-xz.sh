#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

OUTPUT_DIR="$(realpath "${1}")"
NAME="${2}"

if [[ -x autogen.sh ]]; then
    ./autogen.sh
fi

./configure
make dist-xz

mv \
    "${NAME}"-*.tar.xz \
    "${OUTPUT_DIR}/$(
        echo "${NAME}"-*.tar.xz \
        | sed \
            -e "s/${NAME}-/${NAME}_/" \
            -e 's/\.tar\./.orig.tar./'
    )"
