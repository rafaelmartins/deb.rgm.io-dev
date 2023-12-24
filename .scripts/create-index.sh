#!/bin/bash

NUM_ARGS=2

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/utils.sh"

REPOS_DIR="$(realpath "${1}")"
DEB_DIR="$(realpath "${2}")"

function header() {
    cat <<EOF
<!DOCTYPE html>
<html lang="en">

<head>
  <meta charset="utf-8">
  <title>deb.rgm.io</title>
  <meta name="description" content="Debian / Ubuntu repositories" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
</head>

<body>
  <header>
    <h1>deb.rgm.io</h1>
    <h2>Debian / Ubuntu repositories</h2>
  </header>

  <p>
    Repositories are automatically generated using Github Actions and deployed to Github Pages.
  </p>

  <p>
    To install, pick a repository and a distribution, click on the link and download the <code>.sources</code>
    file to <code>/etc/apt/sources.list.d</code>.
  </p>
  <p>
    Example for <code>blogc</code> repository:
  </p>
  <pre><code>$ curl "https://deb.rgm.io/blogc-\$(lsb_release -cs).sources" | sudo tee /etc/apt/sources.list.d/blogc.sources</code></pre>
EOF
}

function footer() {
    cat <<EOF
  <footer>
    <p>
      Service maintained by <a href="https://rgm.io/">Rafael G. Martins</a>.
    </p>
  </footer>

</body>

</html>
EOF
}

function distro_string() {
    p1="$(echo "${1}" | cut -d_ -f1)"
    p2="$(echo "${1}" | cut -d_ -f2)"
    echo "${p1^} ${p2^}"
}

function table() {
    pushd "${DEB_DIR}" > /dev/null
    echo "<table border=\"1\">"

    for repo_name in *; do
        echo "  <tr>"
        echo "    <th style=\"text-align: left\">${repo_name}</th>"

        while read distro; do
            codename="$(echo "${distro}" | cut -d_ -f2)"
            if [[ -d "${repo_name}/${codename}" ]]; then
                echo "    <td><a href=\"./${repo_name}-${codename}.sources\">$(distro_string "${distro}")</a></td>"
            else
                echo "    <td>&nbsp;</td>"
            fi
        done < "${ROOT_DIR}/DISTROS"

        echo "  </tr>"
    done

    echo "</table>"
    popd > /dev/null
}

mkdir -p "${REPOS_DIR}"

header > "${REPOS_DIR}/index.html"
table >> "${REPOS_DIR}/index.html"
footer >> "${REPOS_DIR}/index.html"
