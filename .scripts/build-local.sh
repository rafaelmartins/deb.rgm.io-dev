#!/bin/bash

set -x

NUM_ARGS=4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

SOURCE_DIR="$(realpath "${1}")"
OUTPUT_DIR="$(realpath "${2}")"
REPO_NAME="${3}"
DISTRO="${4}"

tmpdir="$(mktemp -d)"
trap 'rm -rf -- "${tmpdir}"' EXIT

pushd "${SOURCE_DIR}" > /dev/null
git clean -fdx
mkdir -p "${tmpdir}/${REPO_NAME}"
"${ROOT_DIR}/${REPO_NAME}/orig.sh" "${tmpdir}/${REPO_NAME}"
popd > /dev/null

"${SCRIPT_DIR}/build.sh" "${tmpdir}" "${OUTPUT_DIR}" "${REPO_NAME}" "${DISTRO}"
