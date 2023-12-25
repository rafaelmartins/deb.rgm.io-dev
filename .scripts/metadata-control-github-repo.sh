#!/bin/bash

NUM_ARGS=1
DEPENDENCIES="dctrl-tools"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REPO_NAME="${1}"

control="${ROOT_DIR}/${REPO_NAME%%-snapshot}/debian/control"
if [[ ! -f  "${control}" ]]; then
    die "control file not found"
fi

repo="$(
    grep-dctrl \
        --show-field X-GitHub-Repo \
        --no-field-names \
        "" \
        "${control}"
)"
if [[ -z "${repo}" ]]; then
    die "github repository not found"
fi

echo "${repo}"
