#!/bin/bash

NUM_ARGS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

SHA1="${1}"

if [[ "${#SHA1}" -eq 4 ]]; then
    echo "${SHA1}"
    exit 0
fi

if [[ "${#SHA1}" -ne 40 ]]; then
    die "invalid sha1"
fi

echo "${SHA1:0:4}"
