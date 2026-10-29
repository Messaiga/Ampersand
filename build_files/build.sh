#!/bin/bash

set -ouex pipefail

# IMAGE_NAME is passed in from the Containerfile: "ampersand".
IMAGE_NAME="${IMAGE_NAME:-ampersand}"
export IMAGE_NAME

# Copy the contents of system_files/ of the git repo to /
cp -avf "/ctx/system_files"/. /

# Run the numbered build steps in order (10-*.sh, 20-*.sh, ...).
# Each step is a small, single-purpose script; see build_files/README.md.
for step in /ctx/[0-9][0-9]-*.sh; do
    [[ -e "${step}" ]] || continue
    echo "::group:: ${step##*/}"
    bash "${step}"
    echo "::endgroup::"
done
