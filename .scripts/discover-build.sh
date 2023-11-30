#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ORIG_DIR="$(realpath "${1}")"
DEB_DIR="$(realpath "${2}")"

build=()
for repo in $("${SCRIPT_DIR}/metadata-repos.sh"); do
    chl_version_rev="$("${SCRIPT_DIR}/metadata-changelog-version-rev.sh" "${repo}")"
    chl_version="$("${SCRIPT_DIR}/metadata-strip-rev.sh" "${chl_version_rev}")"
    orig_version="$("${SCRIPT_DIR}/metadata-orig-version.sh" "${ORIG_DIR}" "${repo}")"
    orig_ss_version="$("${SCRIPT_DIR}/metadata-orig-version.sh" "${ORIG_DIR}" "${repo}-snapshot")"

    for distro in $("${SCRIPT_DIR}/metadata-distros.sh"); do
        codename="$(echo "${distro}" | cut -d_ -f2)"
        if ! "${SCRIPT_DIR}/metadata-build-for-codename.sh" "${repo}" "${codename}"; then
            continue
        fi

        # release repository
        if [[ "${chl_version}" = "${orig_version}" ]]; then
            deb_version_rev="$("${SCRIPT_DIR}/metadata-deb-version-rev.sh" "${DEB_DIR}" "${repo}" "${codename}")"
            if [[ "${chl_version_rev}" != "${deb_version_rev}" ]]; then
                build+=("${repo} ${distro}")
            fi
        fi

        # snapshot repository
        deb_version_rev="$("${SCRIPT_DIR}/metadata-deb-version-rev.sh" "${DEB_DIR}" "${repo}-snapshot" "${codename}")"
        deb_version="$("${SCRIPT_DIR}/metadata-strip-rev.sh" "${deb_version_rev}")"
        if [[ "${deb_version}" != "${orig_ss_version}" ]]; then
            build+=("${repo}-snapshot ${distro}")
        fi
    done
done

if [[ "${#build[@]}" -eq 0 ]]; then
    build+=("placeholder")
fi

jq \
    -cnM \
    '$ARGS.positional' \
    --args "${build[@]}"
