# Homebrew

Brewfiles declared here are copied into the image at
`/usr/share/ublue-os/homebrew/`. Users install them after boot; nothing is
installed at build time.

## Files

Each is one Ampersand app suite, managed by its `ujust` recipe (a pick list
with a recommended set, spec/05):

- `devmode.Brewfile` — `ujust devmode`: VS Code, containers, editors, dev Flatpaks
- `ai-tools.Brewfile` — `ujust ai-tools`: AI apps and coding agents (replaces
  Common's file of the same name, which it overrides in the image)
- `audio.Brewfile`, `media.Brewfile`, `gaming.Brewfile` — `ujust audio-apps`,
  `media-apps`, `gaming-apps`

Every `brew`/`cask`/`flatpak` line carries a `# Name: description` comment,
which is its menu label; `(recommended)` at the end marks the default set. No
commas in labels (gum splits on them; `build/44-ampersand.sh` fails the build).

The image also ships `/usr/share/ublue-os/homebrew/fonts.Brewfile`, a curated
font set from Common's shared layer, so this directory does not need its own.

## Adding one

Write a `.Brewfile` here with labelled entries, then add a recipe in
`custom/ujust/ampersand.just` that calls `ujust _suite <name> "<Title>"`, like
the existing suites.

## Format

A Brewfile is a Ruby DSL with three kinds of entry:

```ruby
tap "homebrew/cask"           # add a third-party repository
brew "bat"                    # a formula: a CLI tool
brew "eza"
cask "font-jetbrains-mono"    # a cask: a macOS-style package
```

- `tap` comes before anything that needs it.
- `brew` installs formulae.
- `cask` installs macOS-style packages. On Linux only some are available —
  mostly fonts and those that ship a Linux binary.

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
