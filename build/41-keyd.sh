#!/usr/bin/env bash
# keyd: key remapping daemon for the hold-Super one-shot shortcut key
# (config: /etc/keyd/default.conf, from custom/files).
# Not in Fedora yet (review bug 2467653); use the COPR named in keyd's README
# and switch to the Fedora package once it lands.

set -euo pipefail

# shellcheck source=/dev/null
source /ctx/build/copr-helpers.sh

echo "::group:: Install keyd"
copr_install_isolated "alternateved/keyd" keyd
systemctl enable keyd.service
echo "::endgroup::"
