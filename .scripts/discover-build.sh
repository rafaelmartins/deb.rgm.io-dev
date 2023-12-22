#!/bin/bash

export DEBEMAIL="rafael+deb@rafaelmartins.eng.br"
export DEBFULLNAME="Automatic Builder (github-actions)"

NUM_ARGS=3
DEPENDENCIES="devscripts"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

ORIG_DIR="$(realpath "${1}")"
DEB_DIR="$(realpath "${2}")"
OUTPUT_DIR="$(realpath "${3}")"

bdeps=()
build=()
changelog=()
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

        for arch in amd64 arm64 source; do
            # release repository
            if [[ "${chl_version}" = "${orig_version}" ]]; then
                deb_version_rev="$("${SCRIPT_DIR}/metadata-deb-version-rev.sh" "${DEB_DIR}" "${repo}" "${codename}" "${arch}")"
                if [[ -z "${deb_version_rev}" ]] || [[ "${chl_version_rev}" != "${deb_version_rev}" ]]; then
                    build+=("${repo} ${distro} ${arch}")
                    if [[ "${arch}" = source ]]; then
                        changelog+=("${repo} ${distro}")
                    else
                        bdeps+=("${repo} ${arch}")
                    fi
                fi
            fi

            # snapshot repository
            if [[ "${arch}" != arm64 ]] || [[ "${FORCE_ARM64_SNAPSHOTS:-}" == true ]]; then
                deb_version_rev="$("${SCRIPT_DIR}/metadata-deb-version-rev.sh" "${DEB_DIR}" "${repo}-snapshot" "${codename}" "${arch}")"
                orig_ss_version_rev="${orig_ss_version}-$(echo "${chl_version_rev}" | rev | cut -d- -f1 | rev)"
                if [[ -z "${deb_version_rev}" ]] || [[ "${deb_version_rev}" != "${orig_ss_version_rev}" ]]; then
                    build+=("${repo}-snapshot ${distro} ${arch}")
                    if [[ "${arch}" = source ]]; then
                        changelog+=("${repo}-snapshot ${distro}")
                    else
                        bdeps+=("${repo} ${arch}")
                    fi
                fi
            fi
        done
    done
done

for c in "${changelog[@]}"; do
    repo="$(echo "${c}" | cut -d' ' -f1)"
    distro="$(echo "${c}" | cut -d' ' -f2)"
    codename="$(echo "${distro}" | cut -d_ -f2)"
    ver="$(echo "${distro}" | cut -d_ -f3)"

    mkdir -p "${OUTPUT_DIR}/${repo}/${codename}"

    cp \
        "${ROOT_DIR}/${repo%%-snapshot}/debian/changelog" \
        "${OUTPUT_DIR}/${repo}/${codename}/"

    version_revision="$(
        dpkg-parsechangelog \
            -l "${OUTPUT_DIR}/${repo}/${codename}/changelog" \
            -S Version \
        | cut -d~ -f1
    )"

    dch \
        --force-distribution \
        --changelog "${OUTPUT_DIR}/${repo}/${codename}/changelog" \
        --distribution "${codename}" \
        --newversion "${version_revision}~${ver}${codename}" \
        "Automated build for ${codename}"
done

if [[ "${#bdeps[@]}" -eq 0 ]]; then
    bdeps+=("placeholder")
fi

if [[ "${#build[@]}" -eq 0 ]]; then
    build+=("placeholder")
fi

sbdeps="bdeps=$(
    jq \
        -cnM \
        '$ARGS.positional | unique' \
        --args "${bdeps[@]}"
)"

sbuild="build=$(
    jq \
        -cnM \
        '$ARGS.positional' \
        --args "${build[@]}"
)"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
    echo "${sbdeps}" >> "${GITHUB_OUTPUT}"
    echo "${sbuild}" >> "${GITHUB_OUTPUT}"
else
    echo "${sbdeps}"
    echo "${sbuild}"
fi
