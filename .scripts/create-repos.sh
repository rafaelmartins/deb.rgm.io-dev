#!/bin/bash

NUM_ARGS=2
DEPENDENCIES="reprepro"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REPOS_DIR="$(realpath "${1}")"
DEB_DIR="$(realpath "${2}")"

if [[ ! -d "${DEB_DIR}" ]]; then
    exit 0
fi

function reprepro_conf_sections() {
    echo "Origin: ${1}"
    echo "Label: ${1}"
    echo "Codename: ${2}"
    echo "Architectures: source amd64"
    echo "Components: main"
    if [[ "${1}" = *-snapshot ]]; then
        echo "Description: apt repository for ${1} snapshots"
    else
        echo "Description: apt repository for ${1} releases"
    fi
    if [[ -n "${GPG_SIGNING_KEY_ID}" ]]; then
        echo "SignWith: ${GPG_SIGNING_KEY_ID}"
    fi
    echo
}

function sources_file() {
    if [[ ! -e "${REPOS_DIR}/public.key" ]]; then
        gpg \
            --armor \
            --export-options export-minimal \
            --export \
            --output "${REPOS_DIR}/public.key" \
        1>&2
    fi

    echo "Enabled: yes"
    echo "Types: deb deb-src"
    echo "URIs: https://deb.rgm.io/${1}/"
    echo "Suites: ${2}"
    echo "Components: main"
    echo "Architectures: amd64"
    echo "Signed-By:"
    cat "${REPOS_DIR}/public.key"
}

pushd "${DEB_DIR}" > /dev/null

for repo_name in *; do
    rm -rf "${REPOS_DIR}/${repo_name}"
    mkdir -p "${REPOS_DIR}/${repo_name}/conf"

    pushd "${repo_name}" > /dev/null

    for codename in *; do
        reprepro_conf_sections \
            "${repo_name}" \
            "${codename}" \
        >> "${REPOS_DIR}/${repo_name}/conf/distributions"
        sources_file \
            "${repo_name}" \
            "${codename}" \
        >> "${REPOS_DIR}/${repo_name}-${codename}.sources"
    done

    for codename in *; do
        pushd "${REPOS_DIR}/${repo_name}" > /dev/null
        reprepro include "${codename}" "${DEB_DIR}/${repo_name}/${codename}"/*.changes
        popd > /dev/null
    done

    rm -rf "${REPOS_DIR}/${repo_name}/"{db,conf}

    popd > /dev/null
done

popd > /dev/null
