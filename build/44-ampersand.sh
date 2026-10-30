#!/usr/bin/env bash
# Ampersand's files that Finpilot's seams don't cover, the ujust import order,
# and the signing policy. 10-overlay.sh already copied custom/flatpaks,
# custom/brew (our app suites) and custom/ujust into place.

set -ouex pipefail

# Starter VS Code profiles and dev containers (ujust devmode, spec/07).
mkdir -p /usr/share/ampersand
cp -r /ctx/custom/vscode /usr/share/ampersand/vscode

# The suite menu (ujust _suite) passes labels to gum as a comma-separated list.
if grep -nE '^(brew|cask|flatpak) .*# .*,' /ctx/custom/brew/*.Brewfile; then
    echo "::error::a suite label above has a comma; gum can't preselect it"
    exit 1
fi

# ujust: when two imported files define the same recipe, just keeps the one
# imported FIRST. Common's 00-entry.just imports 60-custom.just (our recipes)
# after apps.just and the others, so move that import above them all: then
# Ampersand's [private] stubs hide Common's recipes it replaces.
entry=/usr/share/ublue-os/just/00-entry.just
custom_import='import? "/usr/share/ublue-os/just/60-custom.just"'
if ! grep -qxF "${custom_import}" "${entry}"; then
    echo "::error::${entry} no longer imports 60-custom.just; check how Common's ujust loads local recipes"
    exit 1
fi
awk -v line="${custom_import}" '$0 == line { next } !moved && /^import/ { print line; moved = 1 } { print }' \
    "${entry}" >/tmp/00-entry.just
install -m0644 /tmp/00-entry.just "${entry}"

# Check that ujust now runs our version of every recipe we define.
ours=/usr/share/ublue-os/just/60-custom.just
for recipe in $(just --justfile "${ours}" --dump --dump-format json | jq -r '.recipes | keys[]'); do
    if [[ "$(just --justfile "${entry}" --show "${recipe}")" != "$(just --justfile "${ours}" --show "${recipe}")" ]]; then
        echo "::error::ujust ${recipe} still runs Common's recipe, not Ampersand's"
        exit 1
    fi
done

# Signing (README "Image signing"): trust Ampersand's key for ghcr.io/messaiga,
# so updates over 00-image-info.sh's ostree-image-signed: transport only accept
# images CI signed. Merged into Common's policy with jq, never replaced.
install -Dm0644 /ctx/cosign.pub /usr/lib/pki/containers/messaiga.pub
policy=/etc/containers/policy.json
jq '.transports.docker["ghcr.io/messaiga"] = [{
        "type": "sigstoreSigned",
        "keyPath": "/usr/lib/pki/containers/messaiga.pub",
        "signedIdentity": {"type": "matchRepository"}
    }]' "${policy}" >/tmp/policy.json
install -m0644 /tmp/policy.json "${policy}"
jq -e '.transports.docker["ghcr.io/messaiga"]' "${policy}"
test -f /etc/containers/registries.d/messaiga.yaml || {
    echo "::error::custom/files/etc/containers/registries.d/messaiga.yaml is missing; bootc would not fetch the signature"
    exit 1
}
