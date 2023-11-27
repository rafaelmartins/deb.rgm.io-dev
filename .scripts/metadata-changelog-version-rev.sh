#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

MAIN_DIR="$(realpath "${1}")"
REPO_NAME="${2}"

changelog="${MAIN_DIR}/${REPO_NAME%%-snapshot}/debian/changelog"
if [[ ! -f  "${changelog}" ]]; then
    die "changelog not found"
fi

dpkg-parsechangelog \
    -l "${changelog}" \
    -S Version \
| cut -d~ -f1
