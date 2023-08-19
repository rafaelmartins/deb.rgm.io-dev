#!/bin/bash

set -Eeuo pipefail

tag="$(
    curl \
        --silent \
        --include \
        https://github.com/rafaelmartins/pbuilder-chroots/releases/latest \
    | sed -n '/^location/ s,.*/\([a-z0-9-]*\)[^/]*$,\1,p'
)"

if [[ -z "${tag}" ]]; then
    echo "error: failed to detect lastest pbuilder-chroots tag" > /dev/stderr
    exit 1
fi

echo "https://github.com/rafaelmartins/pbuilder-chroots/releases/download/${tag}"
