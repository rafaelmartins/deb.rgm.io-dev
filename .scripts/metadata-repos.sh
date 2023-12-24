#!/bin/bash

NUM_ARGS=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

pushd "${ROOT_DIR}" > /dev/null

ls \
    -1 \
    -d \
    */debian/ \
2> /dev/null \
| cut -d/ -f1 \
|| true

popd > /dev/null
