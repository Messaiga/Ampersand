#!/bin/bash
# keyd: key remapping daemon for the hold-Super one-shot shortcut key (config: /etc/keyd/default.conf).
# Not in Fedora yet (review bug 2467653); use the COPR named in keyd's README
# and switch to the Fedora package once it lands.

set -ouex pipefail

dnf5 -y copr enable alternateved/keyd
dnf5 -y install keyd
dnf5 -y copr disable alternateved/keyd

systemctl enable keyd.service
