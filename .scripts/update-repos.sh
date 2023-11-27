#!/bin/bash

set -Eeuo pipefail

function die() {
    echo "error:" ${@} > /dev/stderr
    exit 1
}

if [[ $# -ne 2 ]]; then
    die "invalid number of arguments"
fi

debs="$(realpath "${1}")"
repos="$(realpath "${2}")"

for arepo_codename in "${debs}"/*; do
    repo_codename="$(basename "${arepo_codename}")"
    repo="$(echo "${repo_codename}" | cut -d_ -f1)"
    codename="$(echo "${repo_codename}" | cut -d_ -f2)"

    for achanges in "${arepo_codename}"/*.changes; do
        match="$(echo "${achanges}" | rev | cut -d. -f2- | cut -d'~' -f1 | rev)"
        echo $match
    done

    echo $repo $codename
done
