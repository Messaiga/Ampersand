#!/bin/bash
# Put custom/ (apps and ujust recipes) where Bluefin's tools look for them.

set -ouex pipefail

# Default Flatpaks: installed at boot by flatpak-preinstall.service.
install -Dm0644 /ctx/custom/flatpaks/ampersand.preinstall /usr/share/flatpak/preinstall.d/ampersand.preinstall

# Optional Flatpak bundles, installed on request by ujust ampersand-install-*.
install -Dm0644 -t /usr/share/ampersand/flatpaks /ctx/custom/flatpaks/*.Brewfile

# ujust recipes. Bluefin's ujust imports this file name for local additions.
install -Dm0644 /ctx/custom/ujust/ampersand.just /usr/share/ublue-os/just/60-custom.just

if [[ "${IMAGE_NAME}" == "ampersand-dx" ]]; then
    install -Dm0644 /ctx/custom/flatpaks/ampersand-dx.preinstall /usr/share/flatpak/preinstall.d/ampersand-dx.preinstall
    # CLI tools: installed at login by Bluefin's brew-preinstall service.
    install -Dm0644 /ctx/custom/brew/ampersand-dx.Brewfile /usr/share/ublue-os/homebrew/preinstall.d/ampersand-dx.Brewfile
    # Starter VS Code profiles and dev containers, set up by ujust ampersand-vscode.
    mkdir -p /usr/share/ampersand
    cp -r /ctx/custom/vscode /usr/share/ampersand/vscode
fi
