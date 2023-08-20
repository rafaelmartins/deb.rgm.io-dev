#!/bin/bash

set -Eeuo pipefail

if [[ $# -ne 3 ]]; then
    echo "error: Invalid number of arguments" > /dev/stderr
    exit 2
fi

srcdir="${1}"
reposdir="${2}"
baseurl="${3}"

distros=()
for distro in $(curl --silent --location "${baseurl}/DISTROS"); do
    distros+=( "${distro}" )
done

repos=()
for f in $(find "${srcdir}" -type f -name must-rebuild.sh); do
    repos+=( "$(basename "$(dirname "${f}")")" )
done

matrix=()
for repo in "${repos[@]}"; do
    for distro in "${distros[@]}"; do
        if "${srcdir}/${repo}/must-rebuild.sh" "${reposdir}" "$(echo "${distro}" | cut -d_ -f2)"; then
            matrix+=( "${repo} ${distro}" )
        fi
    done
done

jq \
    -cnM \
    '{"build_id": $ARGS.positional}' \
    --args \
    "${matrix[@]}"
