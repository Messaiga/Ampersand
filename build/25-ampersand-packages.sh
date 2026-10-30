#!/usr/bin/env bash

set -euo pipefail

###############################################################################
# Ampersand's packages and removals
###############################################################################
# Runs after 20-packages-and-services.sh, so Finpilot's own package phase stays
# as the template ships it.
#
# Installs:
#   adw-gtk3-theme - GTK3 apps follow libadwaita and the accent colour (spec/03);
#                    Bluefin shipped it, Silverblue does not
#   xdg-terminal-exec - opens the default terminal (Ptyxis) for Ampersand's
#                    shortcuts and setup prompts; Bluefin installed it too
#   unzip, patch   - 40-gnome-extensions.sh unpacks and patches extensions
#   git            - 42-icons.sh clones the pinned icon theme releases
#
# Removes the Silverblue packages Bluefin also removes, from Bluefin's
# EXCLUDED_PACKAGES list (ublue-os/bluefin build_files/base/04-packages.sh):
# Firefox and GNOME Software are Flatpaks/Bazaar here, podman-docker would
# clash with the Docker CLI that `ujust devmode` installs.
###############################################################################

echo "::group:: Install Ampersand packages"

dnf5 install -y adw-gtk3-theme xdg-terminal-exec unzip patch git

echo "::endgroup::"

echo "::group:: Remove Silverblue packages Ampersand replaces"

EXCLUDED_PACKAGES=(
	fedora-bookmarks
	fedora-chromium-config
	fedora-chromium-config-gnome
	firefox
	firefox-langpacks
	gnome-extensions-app
	gnome-shell-extension-background-logo
	gnome-software
	gnome-software-rpm-ostree
	gnome-terminal-nautilus
	podman-docker
	yelp
)

# Only the ones this base actually has: dnf5 fails on a name that is not installed.
readarray -t installed < <(rpm -q --queryformat='%{NAME}\n' "${EXCLUDED_PACKAGES[@]}" 2>/dev/null | grep -v 'is not installed' || true)
if ((${#installed[@]})); then
	dnf5 remove -y "${installed[@]}"
else
	echo "None of the excluded packages are installed."
fi

echo "::endgroup::"
