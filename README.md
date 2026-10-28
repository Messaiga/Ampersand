# Ampersand

An opinionated custom image of [Project Bluefin](https://projectbluefin.io), built with [bootc](https://github.com/bootc-dev/bootc) from the [Universal Blue image template](https://github.com/ublue-os/image-template).

| Image | Based on |
|---|---|
| `ghcr.io/messaiga/ampersand:stable` | `ghcr.io/ublue-os/bluefin:stable` |
| `ghcr.io/messaiga/ampersand-dx:stable` | `ghcr.io/ublue-os/bluefin-dx:stable` |

Both are rebuilt every Wednesday (the day after Bluefin's usual stable release) and on every change to `main`.

## Repository layout

| Path | What goes there |
|---|---|
| `Containerfile` | Picks the base image and runs the build scripts |
| `build_files/` | Build-time scripts (install packages, extensions): anything that needs a command |
| `system_files/` | Files copied into the image as-is (`etc/`, `usr/`): GNOME defaults, configs |
| `custom/` | Flatpak lists, Brewfiles and `ujust` recipes |
| `disk_config/` | Installer ISO configuration |
| `.github/workflows/` | CI: build, sign and publish both variants; build ISOs on demand |

## Building locally

```bash
just build       # ampersand
just build-dx    # ampersand-dx
```

## Signing

Every published image is signed with [cosign](https://github.com/sigstore/cosign). One-time setup, on your own machine, in this repo:

```bash
COSIGN_PASSWORD="" cosign generate-key-pair
gh secret set SIGNING_SECRET < cosign.key   # private key -> GitHub secret
git add cosign.pub                          # public key -> commit it
```

Never commit `cosign.key` (it's in `.gitignore`). Keep a copy somewhere safe offline.

## Installing

Installer ISOs (and qcow2 VM disks) for both variants are built on demand by the *Build disk images* workflow. An installed system only accepts updates signed with `cosign.pub`.

Switching an existing Bluefin machine (for testing) takes two steps, because Bluefin doesn't know Ampersand's key yet:

```bash
sudo bootc switch ghcr.io/messaiga/ampersand-dx:stable          # first switch: unverified
# reboot, then turn on signature checks (Ampersand ships its key):
sudo bootc switch --enforce-container-sigpolicy ghcr.io/messaiga/ampersand-dx:stable
```
