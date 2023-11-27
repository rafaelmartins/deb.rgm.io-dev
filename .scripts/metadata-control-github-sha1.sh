#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

MAIN_DIR="$(realpath "${1}")"
REPO_NAME="${2}"

gh_user_repo="$(
    "${SCRIPT_DIR}/metadata-control-github-repo.sh" \
        "${MAIN_DIR}" \
        "${REPO_NAME}"
)"

git \
    ls-remote \
    https://github.com/${gh_user_repo}.git \
    HEAD \
| cut -d$'\t' -f1
