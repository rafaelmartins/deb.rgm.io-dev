#!/bin/bash

NUM_ARGS=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

git describe \
    --abbrev=4 \
    HEAD \
| sed \
    -e 's/^v//' \
    -e 's/-/./' \
    -e 's/-g/-/'
