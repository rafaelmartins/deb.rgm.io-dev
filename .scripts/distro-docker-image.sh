#!/bin/bash

NUM_ARGS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

CODENAME="${1}"

distro="$("${SCRIPT_DIR}/distro-from-codename.sh" "${CODENAME}")"
if [[ -z "${distro}" ]]; then
    exit 1
fi

imagename="$(echo "${distro}" | cut -d_ -f1)"
imagetag="${CODENAME}"

if [[ "${imagename}" = "debian" ]]; then
    imagetag="${imagetag}-slim"
fi

echo "${imagename}:${imagetag}"
