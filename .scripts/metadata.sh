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

if [[ "x${CI:-}" = "xtrue" ]]; then
    sudo apt update 1>&2
    sudo apt install -y dctrl-tools 1>&2
fi

maindir="${1}"
origdir="${2}"
debdir="${3}"

scriptdir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
rootdir="$(dirname "${scriptdir}")"


function orig_version() {
    if [[ $(ls -1 "${origdir}/${1}"/*.orig.tar.* | wc -l) -ne 1 ]]; then
        die "orig source not valid"
    fi

    ls -1 "${origdir}/${1}"/*.orig.tar.* \
    2> /dev/null \
    | rev \
    | cut -d. -f4- \
    | rev \
    | cut -d_ -f2
}


function repo_version_rev() {
    # we assume that every repo contains only one source package,
    # named the same as the repo (with -snapshot suffix stripped).

    local -a versions

    while read f; do
        versions+=(${f})
    done < <(
        find \
            "${debdir}/${1}/pool" \
            -type f \
            -name "${1%%-snapshot}_*${2}_amd64.deb" \
        2> /dev/null \
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
    local changelog="${maindir}/${1%%-snapshot}/debian/changelog"

    if [[ ! -f  "${changelog}" ]]; then
        die "changelog not found"
    fi

    dpkg-parsechangelog \
        -l "${changelog}" \
        -S Version \
    | cut -d~ -f1
}


function github_repo() {
    local control="${maindir}/${1%%-snapshot}/debian/control"

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
for distro in $(jq -crM ".distro[]" "${rootdir}/DISTROS.json"); do
    distros+=("${distro}")
done

repos=()
for f in $(find "${maindir}" -type d -name debian); do
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
        codename="$(echo "${distro}" | cut -d_ -f2)"

        # release repository
        if dpkg --compare-versions "${chl_version_rev}" gt "$(repo_version_rev "${repo}" "${codename}")"; then
            build_ids+=("${repo} ${distro}")
            sources+=("${repo} $(github_repo "${repo}") v${chl_version}")
        fi

        # snapshot repository
        if [[ "$(repo_version_rev "${repo}-snapshot" "${codename}" | strip_revision)" != "${gh_version}."[0-9]*"-${gh_short_hash}" ]]; then
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
