#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ORIG_DIR="$(realpath "${1}")"
NEW_DIR="$(realpath "${2}")"

pushd "${NEW_DIR}" > /dev/null

for odir in orig_*; do
    dir="$(echo "${odir}" | cut -d_ -f2)"
    orig="$(basename "$(ls -1 "${odir}"/*.orig.* | head -n1)")"
    if [[ -e "${ORIG_DIR}/${dir}/${orig}" ]]; then
        continue
    fi
    rm -rf "${ORIG_DIR}/${dir}"
    mkdir -p "${ORIG_DIR}/${dir}"
    cp -v "${odir}/${orig}" "${ORIG_DIR}/${dir}/"
done

popd > /dev/null

if [[ "x${CI:-}" = "xtrue" ]]; then
    pushd "${ORIG_DIR}" > /dev/null
    git config user.name 'github-actions[bot]'
    git config user.email 'github-actions[bot]@users.noreply.github.com'
    git add .
    git commit -m 'update orig' || true
    popd > /dev/null
fi
