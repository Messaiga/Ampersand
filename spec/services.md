# Services

**Source:** `systemctl` calls in `build/10-overlay.sh`,
`build/20-packages-and-services.sh`, `build/90-cleanup.sh`

## Purpose

systemd units Ampersand turns on or off. The units themselves mostly come from
the Common and Brew overlays; enabling them is what makes the declarations in
`custom/` take effect.

## Current state

| Item | Why it is here |
|---|---|
| `brew-setup.service` | Unpacks Homebrew on first boot. |
| `brew-update.timer` | Keeps Homebrew's metadata current. |
| `brew-upgrade.timer` | Upgrades installed formulae. |
| `brew-preinstall.service` | Per-user (`--global`): installs the image's preinstalled Brew packages. |
| `flatpak-preinstall.service` | Installs `custom/flatpaks/` declarations on first boot. |
| `flatpak-appstream-refresh.service` | Refreshes Flatpak metadata so software centres show current apps. |
| `ublue-system-setup.service` | First-boot system setup hooks. |
| `ublue-user-setup.service` | Per-user (`--global`) first-login setup hooks. |
| `podman.socket` | Rootless container management. |
| `uupd.timer` | Scheduled updates through `uupd`. |
| `uupd-resume.timer` | Catches up on updates after suspend. |
| `flatpak-add-fedora-repos.service` | **Disabled and masked**: the Fedora Flatpak remote is never added; Flathub is the only remote. |
| `rpm-ostreed-automatic.timer` | **Disabled**: `uupd` owns updates, so the base's own updater must not race it. |

All are template defaults, kept as-is.

## Decisions

- **Units are enabled explicitly** — not left to shipped presets, so the build
  script is the single place to read what is on.

## Not included

- `tailscaled.service` — comes with the Tailscale example, not enabled.

## Inherited

- The unit files for Brew — from [ublue-os/brew](https://github.com/ublue-os/brew).
- The unit files for Flatpak preinstall, first-boot setup and the `uupd`
  config, AC-power udev rule and drop-ins — from
  [projectbluefin/common](https://github.com/projectbluefin/common).
