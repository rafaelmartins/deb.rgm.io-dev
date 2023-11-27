#!/bin/bash

NUM_ARGS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

CODENAME="${1}"

# FIXME: sid is not versioned, detect that from json instead of hardcoding
if [[ "x${CODENAME}" = xsid ]]; then
    echo "${CODENAME}"
    exit 0
fi

distro="$(jq -crM ".distro[] | select(contains(\"_${CODENAME}_\"))" "${ROOT_DIR}/DISTROS.json")"
if [[ -z "${distro}" ]]; then
    exit 1
fi

echo "$(echo "${distro}" | cut -d_ -f3)${CODENAME}"
