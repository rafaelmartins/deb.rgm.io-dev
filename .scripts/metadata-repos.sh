#!/bin/bash

NUM_ARGS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

MAIN_DIR="$(realpath "${1}")"

if [[ ! -d "${MAIN_DIR}" ]]; then
    exit 1
fi

pushd "${MAIN_DIR}" > /dev/null

ls \
    -1 \
    -d \
    */debian/ \
| cut -d/ -f1

popd > /dev/null
