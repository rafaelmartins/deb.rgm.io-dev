#!/bin/bash

NUM_ARGS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REPO_NAME="${1}"

gh_user_repo="$(
    "${SCRIPT_DIR}/metadata-control-github-repo.sh" \
        "${REPO_NAME}"
)"

git ls-remote \
    --tags \
    --refs \
    https://github.com/${gh_user_repo}.git \
| rev \
| cut -d/ -f1 \
| rev \
| sort -Vu \
| tail -n1 \
| sed 's/^v//'
