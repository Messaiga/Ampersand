# ujust recipes

**Source:** `custom/ujust/**/*.just`, merged into
`/usr/share/ublue-os/just/60-custom.just` by `build/10-overlay.sh`

## Purpose

Commands users run deliberately. Nothing here runs on login or on an update.

## Current state

| Item | Why it is here |
|---|---|
| `install-default-apps` | Installs `default.Brewfile`. |
| `install-dev-tools` | Installs `development.Brewfile`. |
| `configure-dev-groups` | Adds the user to `docker` and `libvirt`, creating the groups if missing. |
| `install-config` | Re-applies the image's `/etc/skel/.config` defaults, backing up the user's files first. |
| `install-ai-assistant` | App group: Newelle. Will also offer a local LLM as a Quadlet. |
| `install-dev-apps` | App group: developer desktop apps. |
| `install-dx-apps` | App group: Bluefin's developer-experience apps, from upstream. |
| `install-media-apps` | App group: media viewing and conversion. |
| `install-media-production` | App group: audio, video and music production. |
| `install-gaming` | App group: Steam and ProtonPlus. |

The first four are template defaults, kept as-is. The six app-group recipes
are Ampersand's; [flatpaks.md](flatpaks.md) lists each group's apps.

## Decisions

- **User-invoked only** — image updates and logins never overwrite user
  configuration or change group membership.
- **Recipes are merged in sorted order** — the merged file is deterministic, and
  recipes may live in subdirectories.
- **App-group recipes are one line** — each hands its label and Brewfile to
  `/usr/libexec/ampersand/flatpak-group.sh`, so the install / complete /
  uninstall behavior lives, and is tested, in one place.
- **Names avoid Common's recipes** — Common already ships `install-ai-tools`,
  hence `install-ai-assistant`; `install-dev-tools` is the Homebrew CLI
  Brewfile, hence `install-dev-apps`.

## Not included

- Nothing rejected yet.

## Inherited

- The `ujust` entry point and every shared recipe — from
  [projectbluefin/common](https://github.com/projectbluefin/common).
