#!/bin/bash

NUM_ARGS=1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ORIG_DIR="$(realpath "${1}")"

orig=()
for repo in $("${SCRIPT_DIR}/metadata-repos.sh"); do
    gh_repo="$("${SCRIPT_DIR}/metadata-control-github-repo.sh" "${repo}")"

    # release repository
    chl_version_rev="$("${SCRIPT_DIR}/metadata-changelog-version-rev.sh" "${repo}")"
    chl_version="$("${SCRIPT_DIR}/metadata-strip-rev.sh" "${chl_version_rev}")"
    orig_version="$("${SCRIPT_DIR}/metadata-orig-version.sh" "${ORIG_DIR}" "${repo}")"
    if [[ -z "${orig_version}" ]] || dpkg --compare-versions "${chl_version}" gt "${orig_version}"; then
        if [[ "${chl_version//./}" -ne 0 ]]; then
            orig+=("${repo} ${gh_repo} v${chl_version}")
        fi
    fi

    # snapshot repository
    gh_version="$("${SCRIPT_DIR}/metadata-control-github-version.sh" "${repo}")"
    gh_sha1="$("${SCRIPT_DIR}/metadata-control-github-sha1.sh" "${repo}")"
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
