#!/bin/bash

NUM_ARGS=1
DEPENDENCIES="ronn"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)/../.scripts"
source "${SCRIPT_DIR}/utils.sh"

OUTPUT_DIR="$(realpath "${1}")"

"${SCRIPT_DIR}/orig-autotools-xz.sh" \
    "${OUTPUT_DIR}" \
    "blogc"
