#!/bin/bash

NUM_ARGS=2
DEPENDENCIES="dctrl-tools"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

MAIN_DIR="$(realpath "${1}")"
REPO_NAME="${2}"

control="${MAIN_DIR}/${REPO_NAME%%-snapshot}/debian/control"
if [[ ! -f  "${control}" ]]; then
    die "control file not found"
fi

full_repo="$(
    grep-dctrl \
        --show-field Vcs-Git \
        --no-field-names \
        "" \
        "${control}"
)"
if [[ -z "${full_repo}" ]]; then
    die "github repository not found"
fi

echo "${full_repo}" | sed -e 's,^.*github.com[/:],,' -e 's/\.git$//'
