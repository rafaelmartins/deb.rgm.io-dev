#!/bin/bash

NUM_ARGS=3
DEPENDENCIES="dctrl-tools"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

MAIN_DIR="$(realpath "${1}")"
REPO_NAME="${2}"
CODENAME="${3}"

control="${MAIN_DIR}/${REPO_NAME%%-snapshot}/debian/control"
if [[ ! -f  "${control}" ]]; then
    die "control file not found"
fi

codenames="$(
    grep-dctrl \
        --show-field X-Skip-Build-For \
        --no-field-names \
        "" \
        "${control}"
)"

for cname in ${codenames}; do
    if [[ "${cname}" = "${CODENAME}" ]]; then
        exit 1
    fi
done
