# Homebrew

**Source:** `custom/brew/*.Brewfile`

## Purpose

Opt-in software users install through `ujust` shortcuts: CLI tools, and the
Flatpak app groups. Nothing here installs automatically.

## Current state

| Item | Why it is here |
|---|---|
| `default.Brewfile` | Installed by `ujust install-default-apps`. **Empty**: no packages chosen yet. |
| `development.Brewfile` | Installed by `ujust install-dev-tools`. **Empty**: every entry is a commented template suggestion. |
| `ai-assistant.Brewfile` | App group for `ujust install-ai-assistant`. |
| `dev-apps.Brewfile` | App group for `ujust install-dev-apps`. |
| `media.Brewfile` | App group for `ujust install-media-apps`. |
| `media-production.Brewfile` | App group for `ujust install-media-production`. |
| `gaming.Brewfile` | App group for `ujust install-gaming`. |

The app-group Brewfiles hold only `flatpak` lines; their apps are listed in
[flatpaks.md](flatpaks.md).

## Decisions

- **Brew for CLI tools, not RPMs** — user-space, updatable without a reboot,
  and keeps the image lean.
- **Opt-in per Brewfile** — each Brewfile has a matching `ujust` recipe (see
  [ujust.md](ujust.md)).
- **`flatpak` lines are validated by `validate-flatpaks`, not
  `validate-brewfiles`** — they are Flatpak IDs, and that script owns the
  isolated flatpak state. Each must be a literal `flatpak "<app-id>"`.

## Not included

- The commented suggestions in `development.Brewfile` (`kind`, `kubectl`,
  `k9s`, `helm`, `awscli`, `azure-cli`, `go`, `node`, `python@3.12`, `rust`,
  `cmake`, `ninja`, `gdb`, `valgrind`) — template suggestions, not adopted yet.

## Inherited

- Homebrew itself, its shell integration and its units — from
  [ublue-os/brew](https://github.com/ublue-os/brew).
- `system-dx-flatpaks.Brewfile`, copied unchanged from
  [projectbluefin/common](https://github.com/projectbluefin/common)'s
  `bluefin/` tree by `build/10-overlay.sh`.
- Common's shared Brewfiles (`ai-tools`, `cli`, `ide`, `cncf` and others) and
  their `ujust` recipes — from
  [projectbluefin/common](https://github.com/projectbluefin/common).
