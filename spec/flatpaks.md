# Flatpaks

**Source:** `custom/flatpaks/*.preinstall`

## Purpose

GUI applications installed from Flathub on first boot.

## Current state

| Item | Why it is here |
|---|---|
| `org.mozilla.Thunderbird` | Mail, calendar and newsgroups; Fedora ships no mail client. |
| `com.github.tchx84.Flatseal` | Audit and restrict Flatpak permissions; there is no RPM equivalent. |
| `com.mattjakeman.ExtensionManager` | Browse and install GNOME Shell extensions; the packaged app only configures installed ones. |

All three are template defaults, kept as-is.

## Decisions

- **Flathub is the only remote** — its descriptor ships in
  `/etc/flatpak/remotes.d/`, hash-pinned in `build/10-overlay.sh`, and the
  Fedora remote is masked (see [services.md](services.md)).
- **Installed on first boot, not at build time** — keeps the image small and
  apps updatable independently. First boot needs a network connection.
- **App IDs are validated before merge** — `just validate-flatpaks`.

## Not included

- `io.github.flattool.Warehouse` — the commented example in
  `default.preinstall`, not adopted.

## Inherited

- The `flatpak-preinstall.service` unit — from
  [projectbluefin/common](https://github.com/projectbluefin/common).
