# Config and files

**Source:** `custom/config/` (seeded into `/etc/skel/.config/`),
`custom/files/` (overlaid onto `/`)

## Purpose

Default configuration for new users, and system files the image ships by path.

## Current state

| Item | Why it is here |
|---|---|
| `custom/config/environment.d/10-example.conf` | Template example, **inert**: every line is commented out. |

`custom/files/` ships nothing.

## Decisions

- **User defaults reach new accounts only** — existing users get them through
  `ujust install-config`, never automatically.
- **`custom/files/` overlays last** — it wins over Common and Brew, so it can
  replace any inherited file.
- **Never fork an inherited file whole** — for example `policy.json`: copying
  it freezes every upstream scope. Patch it in a build script instead.

## Not included

- Nothing rejected yet.

## Inherited

- Common's shared system files — from
  [projectbluefin/common](https://github.com/projectbluefin/common), overlaid
  before `custom/files/`.
