# Homebrew

Brewfiles declared here are copied into the image at
`/usr/share/ublue-os/homebrew/`. Users install them after boot; nothing is
installed at build time.

## Files

- `default.Brewfile` — the essential CLI tools
- `development.Brewfile` — the development stack
- `ai-assistant`, `dev-apps`, `media`, `media-production`, `gaming` — Flatpak
  app groups (below)

The image also ships `/usr/share/ublue-os/homebrew/fonts.Brewfile`, a curated
font set from Common's shared layer, so this directory does not need its own.

## Adding one

Write a `.Brewfile` here, then add a `ujust` recipe for it in
`custom/ujust/custom-apps.just` so users install it by name instead of
remembering the path. That directory's README has the recipe shape.

## App groups

A Brewfile of only `flatpak "<app-id>"` lines is an app group: a set of GUI
apps a user opts into together. `brew bundle` installs them system-wide
(`flatpak install --system flathub`). Its recipe is one line that hands the
Brewfile to `/usr/libexec/ampersand/flatpak-group.sh`, which installs the whole
group, or offers to complete or remove it when some or all of it is installed:

```just
# Install, complete or remove the gaming apps
[group('Apps')]
install-gaming:
    #!/usr/bin/env bash
    set -euo pipefail
    exec /usr/bin/bash /usr/libexec/ampersand/flatpak-group.sh "gaming" /usr/share/ublue-os/homebrew/gaming.Brewfile
```

Keep each entry a literal with no options: `just validate-flatpaks` resolves
every one on Flathub and fails a line it cannot check. List the group in
`spec/flatpaks.md`; the contract test fails until it is there.

`ujust install-dx-apps` is the exception: its Brewfile is Bluefin's
`system-dx-flatpaks.Brewfile`, which `build/10-overlay.sh` copies unchanged from
Common rather than from this directory.

## Format

A Brewfile is a Ruby DSL with four kinds of entry:

```ruby
tap "homebrew/cask"           # add a third-party repository
brew "bat"                    # a formula: a CLI tool
brew "eza"
cask "font-jetbrains-mono"    # a cask: a macOS-style package
flatpak "org.videolan.VLC"    # a Flatpak, from Flathub
```

- `tap` comes before anything that needs it.
- `brew` installs formulae.
- `cask` installs macOS-style packages. On Linux only some are available —
  mostly fonts and those that ship a Linux binary.
- `flatpak` installs a Flatpak system-wide. `just validate-flatpaks` checks
  these, not `just validate-brewfiles`.

A repository Brewfile is never evaluated — that would be code execution from a
pull request. `just validate-brewfiles` checks one literally instead, and the
pre-commit hook calls the same script.

## Using them

```bash
brew bundle --file /usr/share/ublue-os/homebrew/default.Brewfile
```

or, on an image built from this template:

```bash
ujust install-default-apps
ujust install-dev-tools
```

Homebrew itself is pre-staged at build time and unpacked on first boot by
`brew-setup.service`.
