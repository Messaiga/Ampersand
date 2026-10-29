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

# When two imported files define the same recipe, just keeps the one imported
# FIRST. Bluefin imports 60-custom.just near the end, so move that import above
# all the others: then our recipes replace Bluefin's (devmode, bluespeed...).
entry=/usr/share/ublue-os/just/00-entry.just
custom_import='import? "/usr/share/ublue-os/just/60-custom.just"'
if ! grep -qxF "${custom_import}" "${entry}"; then
    echo "::error::${entry} no longer imports 60-custom.just; check how Bluefin's ujust loads local recipes"
    exit 1
fi
awk -v line="${custom_import}" '$0 == line { next } !moved && /^import/ { print line; moved = 1 } { print }' \
    "${entry}" >/tmp/00-entry.just
install -m0644 /tmp/00-entry.just "${entry}"

# Bluefin's 60-bonedigger.just only defines `ujust report`, which Ampersand
# hides; remove it, but stop if Bluefin ever adds more recipes there.
bonedigger=/usr/share/ublue-os/just/60-bonedigger.just
if [[ -f "${bonedigger}" ]]; then
    recipes="$(just --justfile "${bonedigger}" --summary)"
    if [[ "${recipes}" != "report" ]]; then
        echo "::error::${bonedigger} now defines: ${recipes}. Review before removing it."
        exit 1
    fi
    rm -f "${bonedigger}"
fi

# Check that ujust now runs our version of every recipe we define.
ours=/usr/share/ublue-os/just/60-custom.just
for recipe in $(just --justfile "${ours}" --dump --dump-format json | jq -r '.recipes | keys[]'); do
    if [[ "$(just --justfile "${entry}" --show "${recipe}")" != "$(just --justfile "${ours}" --show "${recipe}")" ]]; then
        echo "::error::ujust ${recipe} still runs Bluefin's recipe, not Ampersand's"
        exit 1
    fi
done
