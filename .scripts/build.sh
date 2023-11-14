#!/bin/bash

set -Eeuo pipefail

export DEBEMAIL="rafael+deb@rafaelmartins.eng.br"
export DEBFULLNAME="Automatic Builder (github-actions)"

function die() {
    echo "error:" ${@} > /dev/stderr
    exit 1
}

if [[ $# -ne 5 ]]; then
    die "invalid number of arguments"
fi

if [[ "x${CI:-}" = "xtrue" ]]; then
    #sudo sed -i 's/^# deb-src/deb-src/' /etc/apt/sources.list 1>&2
    #sudo apt update 1>&2
    sudo apt install -y devscripts equivs 1>&2
fi

repo="${1}"
codename="${2}"
source="$(realpath "${3}")"
repodir="$(realpath "${4}")"
outdir="$(realpath "${5}")"

scriptdir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

image="$("${scriptdir}/distro-docker-image.sh" "${codename}")"

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "${tmpdir}"' EXIT

mkdir -p "${tmpdir}"/build{,deps}

# FIXME: this could be moved to source phase
pushd "${tmpdir}/builddeps" > /dev/null
mk-build-deps "${repodir}/debian/control"
popd > /dev/null

version="$(
    echo "$(basename "${source}")" \
    | sed 's/\.orig\..*$//' \
    | cut -d_ -f2
)"

tar \
    --extract \
    --verbose \
    --file "${source}" \
    --directory "${tmpdir}/build"

cp \
    "${source}" \
    "${tmpdir}/build/"

builddir="$(
    find \
        "${tmpdir}/build" \
        -maxdepth 1 \
        -type d \
        -iname "${repo%%-snapshot}*" \
    | head -n 1
)"

pushd "${builddir}" > /dev/null

cp \
    --recursive \
    "${repodir}/debian" \
    .

if ! dch \
    --distribution "${codename}" \
    --newversion "${version}-1~$("${scriptdir}/distro-version-suffix.sh" "${codename}")" \
    "Automated build for ${codename}"
then
    exit 0
fi

popd > /dev/null

docker run \
    --pull=always \
    --rm \
    --init \
    --env DEB_BUILD_OPTIONS=noddebs \
    --env DEBIAN_FRONTEND=noninteractive \
    --volume "${tmpdir}/build:/build" \
    --volume "${tmpdir}/builddeps:/builddeps" \
    --workdir "/build/$(basename "${builddir}")" \
    "${image}" \
    bash \
        -c "\
            apt update \
                && apt install -y --no-install-recommends /builddeps/*.deb \
                && dpkg-buildpackage -uc -us -sa; \
            chown -R $(id -u):$(id -g) /build \
        "

mkdir -p "${outdir}"

find \
    "${tmpdir}/build" \
    -maxdepth 1 \
    -type f \
    -exec cp -- "{}" "${outdir}/" \;
