set -Eeuo pipefail

function die() {
    echo "error:" "${@}" > /dev/stderr
    exit 1
}

if [[ -n "${NUM_ARGS}" ]] && [[ $# -ne ${NUM_ARGS} ]]; then
    die "invalid number of arguments"
fi

if [[ -z "${SCRIPT_DIR}" ]]; then
    die "SCRIPT_DIR not defined"
fi

if [[ "x${CI:-}" = "xtrue" ]] && [[ -n "${DEPENDENCIES}" ]]; then
    sudo apt update 1>&2
    sudo apt install -y ${DEPENDENCIES} 1>&2
fi

ROOT_DIR="$(dirname "${SCRIPT_DIR}")"
