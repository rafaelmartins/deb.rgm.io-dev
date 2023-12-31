#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ORIG_DIR="$(realpath "${1}")"
REPO_NAME="${2}"

ls \
    -1 \
    "${ORIG_DIR}/${REPO_NAME}"/*.orig.tar.* \
2> /dev/null \
| rev \
| cut -d. -f4- \
| rev \
| cut -d_ -f2 \
|| true
