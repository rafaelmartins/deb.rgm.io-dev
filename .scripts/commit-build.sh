#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

DEB_DIR="$(realpath "${1}")"
NEW_DIR="$(realpath "${2}")"

if [[ ! -d "${NEW_DIR}" ]]; then
    exit 0
fi

pushd "${NEW_DIR}" > /dev/null

for bdir in build--*; do
    build_id="$(echo "${bdir}" | cut -d- -f3-)"
    repo_name="$(echo "${build_dir}" | cut -d' ' -f1)"
    distro="$(echo "${build_dir}" | cut -d' ' -f2)"
    codename="$(echo "${distro}" | cut -d_ -f2)"

    rm -rf "${DEB_DIR}/${repo_name}/${codename}"
    mkdir -p "${DEB_DIR}/${repo_name}/${codename}"

    cp \
        -v \
        -r \
        "${bdir}/"* \
        "${DEB_DIR}/${repo_name}/${codename}/"
done

popd > /dev/null

if [[ "x${CI:-}" = "xtrue" ]]; then
    pushd "${DEB_DIR}" > /dev/null
    git config user.name 'github-actions[bot]'
    git config user.email 'github-actions[bot]@users.noreply.github.com'
    git add .
    git commit -m 'update build' || true
    popd > /dev/null
fi
