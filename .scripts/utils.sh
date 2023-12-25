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

ROOT_DIR="$(dirname "${SCRIPT_DIR}")"

DEPENDENCIES="${DEPENDENCIES:-}"
if [[ "x${CI:-}" = "xtrue" ]] && [[ -n "${DEPENDENCIES}" ]]; then
    export DEBIAN_FRONTEND=noninteractive

    if [[ ! -e "${ROOT_DIR}/.apt-updated" ]]; then
        sudo apt update 1>&2
        touch "${ROOT_DIR}/.apt-updated"
    fi

    deps=()
    for dep in ${DEPENDENCIES}; do
        if [[ -z "$(apt list -qq --installed "${dep}")" ]]; then
            deps+=("${dep}")
        fi
    done

    sudo apt install -y ${deps[@]} 1>&2
fi
