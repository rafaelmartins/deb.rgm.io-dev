#!/bin/bash

set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
    echo "error: Invalid number of arguments" > /dev/stderr
    exit 2
fi

baseurl="$("${1}/.scripts/pbuilder-chroots_baseurl.sh")"

distros=()
for distro in $(curl --silent --location "${baseurl}/DISTROS"); do
    distros+=( "${distro}" )
done

repos=()
for f in $(find "${1}" -type f -name must-rebuild.sh); do
    repos+=( "$(basename "$(dirname "${f}")")" )
done

matrix=()
for repo in "${repos[@]}"; do
    for distro in "${distros[@]}"; do
        if "${1}/${repo}/must-rebuild.sh" "${2}" "$(echo "${distro}" | cut -d_ -f2)"; then
            matrix+=( "${repo} ${distro}" )
        fi
    done
done

jq \
    -cnM \
    '{"build_id": $ARGS.positional}' \
    --args \
    "${matrix[@]}"
