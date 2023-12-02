#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ORIG_DIR="$(realpath "${1}")"
NEW_DIR="$(realpath "${2}")"

pushd "${ORIG_DIR}" > /dev/null

# cleanup removed repositories
for orepo in *; do
    found=
    for mrepo in $("${SCRIPT_DIR}/metadata-repos.sh"); do
        if [[ "${orepo}" = "${mrepo}" ]]; then
            found=1
            break
        fi
        if [[ "${orepo}" = "${mrepo}-snapshot" ]]; then
            found=1
            break
        fi
    done
    if [[ -z "${found}" ]]; then
        rm -rvf "${orepo}"
    fi
done

popd > /dev/null

if ls "${NEW_DIR}"/orig--* &> /dev/null; then
    pushd "${NEW_DIR}" > /dev/null

    # add new files
    for odir in orig--*; do
        dir="$(echo "${odir}" | cut -d- -f3-)"
        orig="$(basename "$(ls -1 "${odir}"/*.orig.* | head -n1)")"
        if [[ -e "${ORIG_DIR}/${dir}/${orig}" ]]; then
            continue
        fi
        rm -rf "${ORIG_DIR}/${dir}"
        mkdir -p "${ORIG_DIR}/${dir}"
        cp -v "${odir}/${orig}" "${ORIG_DIR}/${dir}/"
    done

    popd > /dev/null
fi

if [[ "x${CI:-}" = "xtrue" ]]; then
    pushd "${ORIG_DIR}" > /dev/null
    if [[ $(git status --porcelain=v1 | wc -l) -gt 0 ]]; then
        git config user.name 'github-actions[bot]'
        git config user.email 'github-actions[bot]@users.noreply.github.com'
        git checkout --orphan temp
        git add .
        git commit -m 'update orig' || true
        git push --force origin HEAD:orig
    fi
    popd > /dev/null
fi
