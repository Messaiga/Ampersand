# Removed or disabled

**Source:** `build/90-cleanup.sh`, `build/*.sh.example`, `Containerfile`

## Purpose

What Ampersand takes away from its base, and the template options it leaves
switched off.

## Current state

| Item | Why it is here |
|---|---|
| `flatpak-add-fedora-repos.service` | Masked and removed: Flathub is the only Flatpak remote. |
| `rpm-ostreed-automatic.timer` | Disabled: `uupd` owns updates. |
| `/opt` | Replaced by a symlink to `/var/opt`, so it is writable at runtime. |
| Third-party repositories | Every COPR, RPM Fusion, `fedora-multimedia`, `tailscale`, `fedora-cisco-openh264` and `fedora-coreos-pool` repo is disabled before the image ships; the build fails if one is still enabled. |

All are template defaults, kept as-is.

## Decisions

- **Nothing is removed from the Silverblue package set** — the image adds; it
  does not strip.

## Not included

These template examples are present in `build/` but not wired into the
`Containerfile`:

- `build/30-tailscale.sh.example` — Tailscale from the vendor repository.
- `build/40-gnome-extensions.sh.example` — system-wide GNOME Shell extensions.
- `build/50-nvidia.sh.example` — NVIDIA driver and container toolkit.
- `build/60-desktop-swap.sh.example` — replaces GNOME with COSMIC.

## Inherited

- Nothing; removals are Ampersand's own.
