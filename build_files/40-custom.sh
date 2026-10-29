#!/bin/bash
# Put custom/ (apps and ujust recipes) where Bluefin's tools look for them.

set -ouex pipefail

# Default Flatpaks: installed at boot by flatpak-preinstall.service.
install -Dm0644 /ctx/custom/flatpaks/ampersand.preinstall /usr/share/flatpak/preinstall.d/ampersand.preinstall

# Optional Flatpak bundles, toggled by ujust ampersand-audio / -media / -gaming.
install -Dm0644 -t /usr/share/ampersand/flatpaks /ctx/custom/flatpaks/*.Brewfile

# Developer tools (ujust devmode), the AI tools picker (ujust ampersand-ai-tools),
# and the starter VS Code profiles and dev containers.
mkdir -p /usr/share/ampersand
cp -r /ctx/custom/devmode /usr/share/ampersand/devmode

# ujust recipes. Bluefin's ujust imports this file name for local additions.
install -Dm0644 /ctx/custom/ujust/ampersand.just /usr/share/ublue-os/just/60-custom.just

# Bluefin's 60-bonedigger.just only defines `ujust report`, which Ampersand
# hides. It's imported after our file, so we can't override it; remove it, but
# stop if Bluefin ever adds more recipes there.
bonedigger=/usr/share/ublue-os/just/60-bonedigger.just
if [[ -f "${bonedigger}" ]]; then
    recipes="$(just --justfile "${bonedigger}" --summary)"
    if [[ "${recipes}" != "report" ]]; then
        echo "::error::${bonedigger} now defines: ${recipes}. Review before removing it."
        exit 1
    fi
    rm -f "${bonedigger}"
fi
