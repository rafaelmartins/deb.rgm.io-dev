#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

MAIN_DIR="$(realpath "${1}")"
REPO_NAME="${2}"


function github_repo() {
    local control="${MAIN_DIR}/${1%%-snapshot}/debian/control"

    if [[ ! -f  "${control}" ]]; then
        die "control file not found"
    fi

    grep-dctrl \
        --show-field Vcs-Git \
        --no-field-names \
        "" \
        "${control}" \
    | sed -e 's,^.*github.com[/:],,' -e 's/\.git$//'
}

gh_repo="$(github_repo "${REPO_NAME}")"

curl \
    --fail-with-body \
    --silent \
    --include \
    "https://github.com/${gh_repo}/releases/latest" \
| sed -n '/^[Ll]ocation:/ s,.*/v\([\.a-z0-9-]*\)[^/]*$,\1,p'
