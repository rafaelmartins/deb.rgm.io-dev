#!/bin/bash

NUM_ARGS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

VERSION_REV="${1}"

echo "${VERSION_REV}" \
| rev \
| cut -d- -f2- \
| rev
