#!/bin/bash

NUM_ARGS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

CODENAME="${1}"

while read distro; do
    if [[ "$(echo $distro | cut -d_ -f2)" = "${CODENAME}" ]]; then
        echo $distro
        exit 0
    fi
done < "${ROOT_DIR}/DISTROS"
