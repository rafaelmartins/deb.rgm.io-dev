#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

MAIN_DIR="$(realpath "${1}")"
ORIG_DIR="$(realpath "${2}")"

orig=()
for repo in $("${SCRIPT_DIR}/metadata-repos.sh" "${MAIN_DIR}"); do
    gh_repo="$("${SCRIPT_DIR}/metadata-control-github-repo.sh" "${MAIN_DIR}" "${repo}")"

    # release repository
    chl_version_rev="$("${SCRIPT_DIR}/metadata-changelog-version-rev.sh" "${MAIN_DIR}" "${repo}")"
    chl_version="$("${SCRIPT_DIR}/metadata-strip-rev.sh" "${chl_version_rev}")"
    orig_version="$("${SCRIPT_DIR}/metadata-orig-version.sh" "${ORIG_DIR}" "${repo}")"
    if [[ -z "${orig_version}" ]] || dpkg --compare-versions "${chl_version}" gt "${orig_version}"; then
        orig+=("${repo} ${gh_repo} v${chl_version}")
    fi

    # snapshot repository
    gh_version="$("${SCRIPT_DIR}/metadata-github-version.sh" "${MAIN_DIR}" "${repo}")"
    gh_sha1="$("${SCRIPT_DIR}/metadata-control-github-sha1.sh" "${MAIN_DIR}" "${repo}")"
    gh_short_sha1="$("${SCRIPT_DIR}/metadata-short-sha1.sh" "${gh_sha1}")"
    orig_ss_version="$("${SCRIPT_DIR}/metadata-orig-version.sh" "${ORIG_DIR}" "${repo}-snapshot")"
    if [[ -z "${orig_ss_version}" ]] || [[ "${orig_ss_version}" != "${gh_version}."[0-9]*"-${gh_short_sha1}" ]]; then
        orig+=("${repo}-snapshot ${gh_repo} ${gh_sha1}")
    fi
done

if [[ "${#orig[@]}" -eq 0 ]]; then
    orig+=("placeholder")
fi

jq \
    -cnM \
    '$ARGS.positional' \
    --args "${orig[@]}"
