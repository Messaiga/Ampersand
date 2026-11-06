# Homebrew

**Source:** `custom/brew/*.Brewfile`

## Purpose

CLI tools users opt into after install, through `ujust` shortcuts. Nothing here
installs automatically.

## Current state

| Item | Why it is here |
|---|---|
| `default.Brewfile` | Installed by `ujust install-default-apps`. **Empty**: no packages chosen yet. |
| `development.Brewfile` | Installed by `ujust install-dev-tools`. **Empty**: every entry is a commented template suggestion. |

## Decisions

- **Brew for CLI tools, not RPMs** — user-space, updatable without a reboot,
  and keeps the image lean.
- **Opt-in per Brewfile** — each Brewfile has a matching `ujust` recipe (see
  [ujust.md](ujust.md)).

## Not included

- The commented suggestions in `development.Brewfile` (`kind`, `kubectl`,
  `k9s`, `helm`, `awscli`, `azure-cli`, `go`, `node`, `python@3.12`, `rust`,
  `cmake`, `ninja`, `gdb`, `valgrind`) — template suggestions, not adopted yet.

## Inherited

- Homebrew itself, its shell integration and its units — from
  [ublue-os/brew](https://github.com/ublue-os/brew).
