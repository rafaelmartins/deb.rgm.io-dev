#!/bin/bash

NUM_ARGS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REPO_NAME="${1}"

changelog="${ROOT_DIR}/${REPO_NAME%%-snapshot}/debian/changelog"
if [[ ! -f  "${changelog}" ]]; then
    die "changelog not found"
fi

dpkg-parsechangelog \
    -l "${changelog}" \
    -S Version \
| cut -d~ -f1
