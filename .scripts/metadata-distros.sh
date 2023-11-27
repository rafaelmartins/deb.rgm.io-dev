#!/bin/bash

NUM_ARGS=0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

jq -crM ".distro[]" "${ROOT_DIR}/DISTROS.json"
