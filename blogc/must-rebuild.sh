#!/bin/bash

set -Eeuo pipefail

if [[ $# -ne 2 ]]; then
    echo "error: Invalid number of arguments" > /dev/stderr
    exit 2
fi

dir="$(realpath "$(dirname "${0}")")"
exec "${dir}/../.scripts/must-rebuild_release.sh" "${dir}" blogc blogc "${@}"
