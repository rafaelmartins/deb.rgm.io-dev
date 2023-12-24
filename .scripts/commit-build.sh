#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

DEB_DIR="$(realpath "${1}")"
NEW_DIR="$(realpath "${2}")"

pushd "${DEB_DIR}" > /dev/null

# cleanup removed repositories
for drepo in *; do
    if [[ ! -d "${drepo}" ]]; then
        continue
    fi

    found=
    for mrepo in $("${SCRIPT_DIR}/metadata-repos.sh"); do
        if [[ "${drepo}" = "${mrepo}" ]]; then
            found=1
            break
        fi
        if [[ "${drepo}" = "${mrepo}-snapshot" ]]; then
            found=1
            break
        fi
    done
    if [[ -z "${found}" ]]; then
        rm -rvf "${drepo}"
        continue
    fi

    pushd "${drepo}" > /dev/null

    for cname in *; do
        found=
        while read distro; do
            codename="$(echo "${distro}" | cut -d_ -f2)"
            if [[ "${cname}" = "${codename}" ]]; then
                found=1
                break
            fi
        done < "${ROOT_DIR}/DISTROS"
        if [[ -z "${found}" ]]; then
            rm -rvf "${cname}"
        fi
    done

    popd > /dev/null
done

popd > /dev/null

if ls "${NEW_DIR}"/build--* &> /dev/null; then
    pushd "${NEW_DIR}" > /dev/null

    # add new files
    for bdir in build--*; do
        build_id="$(echo "${bdir}" | cut -d- -f3-)"
        repo_name="$(echo "${build_id}" | cut -d' ' -f1)"
        distro="$(echo "${build_id}" | cut -d' ' -f2)"
        arch="$(echo "${build_id}" | cut -d' ' -f3)"
        codename="$(echo "${distro}" | cut -d_ -f2)"

        if [[ "${arch}" = source ]]; then
            rm -f "${DEB_DIR}/${repo_name}/${codename}/"*{.debian.tar.*,.dsc}
        else
            rm -f "${DEB_DIR}/${repo_name}/${codename}/"*"_${arch}."*
        fi
        mkdir -p "${DEB_DIR}/${repo_name}/${codename}"

        cp \
            -v \
            -r \
            "${bdir}/"* \
            "${DEB_DIR}/${repo_name}/${codename}/"
    done

    popd > /dev/null
fi

cat <<EOF > "${DEB_DIR}/README.md"
# deb

DO NOT TOUCH THIS BRANCH!
EOF

if [[ "x${CI:-}" = "xtrue" ]]; then
    pushd "${DEB_DIR}" > /dev/null
    if [[ $(git status --porcelain=v1 | wc -l) -gt 0 ]]; then
        git config user.name 'github-actions[bot]'
        git config user.email 'github-actions[bot]@users.noreply.github.com'
        git checkout --orphan temp
        git add .
        git commit -m 'update deb' || true
        git push --force origin HEAD:deb
    fi
    popd > /dev/null
fi
