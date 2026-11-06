# Packages

**Source:** `build/20-packages-and-services.sh`, `build/copr-helpers.sh`

## Purpose

RPM and COPR packages baked into the image at build time. Only what the image
needs to work on first boot belongs here; user tools go in Homebrew or Flatpak.

## Current state

| Item | Why it is here |
|---|---|
| `just` | The `ujust` entry point; Fedora ships no `just` binary. |
| `gum` | Interactive prompts in the shared and custom `ujust` recipes. |
| `fzf` | `ujust --choose` without a first-use Homebrew download. |
| `jq` | Used by the ublue setup hooks and several recipes. |
| `uupd` | Background update policy (system, Flatpak, Brew), from the `ublue-os/packages` COPR. |

All five are template defaults, kept as-is.

## Decisions

- **Packages install only in `20-packages-and-services.sh`** — never in the
  overlay phase, so editing an overlay does not invalidate the expensive
  package layer.
- **COPRs go through `copr_install_isolated`** — enables the COPR for one
  install and disables it again, so no third-party source stays live.
- **Weak dependencies are off during the build** — `install_weak_deps=0`, then
  reverted by `90-cleanup.sh` so packages a user layers later behave normally.

## Not included

- `tailscale` — `build/30-tailscale.sh.example`, not enabled.
- NVIDIA driver and container toolkit — `build/50-nvidia.sh.example`, not
  enabled.

## Inherited

- Every package in the Silverblue base — from the
  [Fedora OSTree desktop](https://quay.io/repository/fedora-ostree-desktops/silverblue)
  image.
