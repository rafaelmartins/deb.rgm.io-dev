#!/bin/bash

set -Eeuo pipefail

function die() {
    echo "error:" ${@} > /dev/stderr
    exit 1
}

if [[ $# -ne 1 ]]; then
    die "invalid number of arguments"
fi

codename="${1}"

scriptdir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
rootdir="$(dirname "${scriptdir}")"

distro="$(jq -crM ".distro[] | select(contains(\"_${codename}_\"))" "${rootdir}/DISTROS.json")"
if [[ -z "${distro}" ]]; then
    exit 1
fi

echo "$(echo "${distro}" | cut -d_ -f3)${codename}"
