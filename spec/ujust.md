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

All four are template defaults, kept as-is.

## Decisions

- **User-invoked only** — image updates and logins never overwrite user
  configuration or change group membership.
- **Recipes are merged in sorted order** — the merged file is deterministic, and
  recipes may live in subdirectories.

## Not included

- Nothing rejected yet.

## Inherited

- The `ujust` entry point and every shared recipe — from
  [projectbluefin/common](https://github.com/projectbluefin/common).
