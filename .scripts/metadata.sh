#!/bin/bash

set -Eeuo pipefail

# FIXME: support epoch?

function die() {
    echo "error:" ${@} > /dev/stderr
    exit 1
}

if [[ $# -ne 3 ]]; then
    die "invalid number of arguments"
fi

srcdir="${1}"
reposdir="${2}"
baseurl="${3}"


function repo_version_rev() {
    # we assume that every repo only contains only one package (splitted packages
    # are fine), and that there's always a package with the repository name.

    local -a versions

    while read f; do
        versions+=(${f})
    done < <(
        find \
            "${reposdir}/${1}/pool" \
            -type f \
            -name "${1/-snapshot/}_*${2}_amd64.deb" \
        | rev \
        | cut -d_ -f2 \
        | rev \
        | cut -d~ -f1 \
        | sort -u
    )

    if [[ -n "${versions[@]}" ]] && [[ ${#versions[@]} -gt 1 ]]; then
        die "more than one version found in repository: ${1}"
    fi

    echo ${versions[@]}
}


function changelog_version_rev() {
    local changelog="${srcdir}/${1/-snapshot/}/debian/changelog"

    if [[ ! -f  "${changelog}" ]]; then
        die "changelog not found"
    fi

    dpkg-parsechangelog \
        -l "${changelog}" \
        -S Version \
    | cut -d~ -f1
}


function github_repo() {
    local control="${srcdir}/${1/-snapshot/}/debian/control"

    if [[ ! -f  "${control}" ]]; then
        die "control file not found"
    fi

    grep-dctrl \
        --show-field Vcs-Git \
        --no-field-names \
        "" \
        "${control}" \
    | sed -e 's,^.*github.com[/:],,' -e 's/\.git$//'
}


function github_version() {
    curl \
        --fail-with-body \
        --silent \
        --include \
        "https://github.com/$(github_repo "${1}")/releases/latest" \
    | sed -n '/^location:/ s,.*/v\([\.a-z0-9-]*\)[^/]*$,\1,p'
}


function github_hash() {
    git \
        ls-remote \
        https://github.com/$(github_repo "${1}").git \
        HEAD \
    | cut -d$'\t' -f1
}


function short_hash() {
    echo "${1:0:4}"
}


function strip_revision() {
    rev \
    | cut -d- -f2- \
    | rev
}


distros=()
for distro in $(curl --silent --location "${baseurl}/DISTROS"); do
    distros+=("${distro}")
done

repos=()
for f in $(find "${srcdir}" -type d -name debian); do
    repos+=("$(basename "$(dirname "${f}")")")
done

build_ids=()
sources=()

for repo in "${repos[@]}"; do
    chl_version_rev="$(changelog_version_rev "${repo}")"
    chl_version="$(echo "${chl_version_rev}" | strip_revision)"
    gh_version="$(github_version "${repo}-snapshot")"
    gh_hash="$(github_hash "${repo}-snapshot")"
    gh_short_hash="$(short_hash "${gh_hash}")"

    for distro in "${distros[@]}"; do
        variant="$(echo "${distro}" | cut -d_ -f2)"

        # release repository
        if dpkg --compare-versions "${chl_version_rev}" gt "$(repo_version_rev "${repo}" "${variant}")"; then
            build_ids+=("${repo} ${distro}")
            sources+=("${repo} $(github_repo "${repo}") v${chl_version}")
        fi

        # snapshot repository
        if [[ "$(repo_version_rev "${repo}-snapshot" "${variant}" | strip_revision)" != "${gh_version}."[0-9]*"-${gh_short_hash}" ]]; then
            build_ids+=("${repo}-snapshot ${distro}")
            sources+=("${repo}-snapshot $(github_repo "${repo}") ${gh_hash}")
        fi
    done
done

jq \
    -cnM \
    --argjson buildids "$(jq -cnM '$ARGS.positional' --args "${build_ids[@]}")" \
    --argjson sources "$(jq -cnM '$ARGS.positional | unique' --args "${sources[@]}")" \
    '{"build_id": $buildids, "source": $sources}'
