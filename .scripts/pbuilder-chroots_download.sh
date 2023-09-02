#!/bin/bash

set -Eeuo pipefail

function die() {
    echo "error:" ${@} > /dev/stderr
    exit 1
}

if [[ $# -ne 2 ]]; then
    die "invalid number of arguments"
fi

baseurl="${1}"
distro="${2}"

tag="$(echo "${baseurl}" | rev | cut -d/ -f1 | rev)"
fname="pbuilder-chroot-${distro}-${tag/pbuilder-chroots-/}.tar.xz"

wget \
    --continue \
    "${baseurl}/${fname}"{,.sha512}

sha512sum \
    --check \
    --status \
    "${fname}.sha512"

sudo rm -rf ./chroot
mkdir -p ./chroot

fakeroot \
    tar \
        --checkpoint=1000 \
        -xf "${fname}" \
        -C ./chroot

rm -f "${fname}"{,.sha512}
