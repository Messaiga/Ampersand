---
name: overview
description: >-
  Architecture, repository layout, and file map for this template.
  Use when orienting to the repository, tracing how the image is assembled,
  or deciding which skill covers a task.
---

# Overview

This repository builds a bootc operating system image by assembling OCI layers
rather than by modifying an existing image. Bluefin, Aurora, and Bluefin LTS are
built the same way, so the desktop configuration here is the one they ship.

## How the image is assembled

The `Containerfile` is the source of truth, and it is deliberately verbose. It
defines three things:

1. **Context stage** (`ctx`) — combines the local `build/` and `custom/`
   directories with files pulled from two OCI images:

   - `ghcr.io/projectbluefin/common` — the shared desktop configuration,
     branding, and the Brew/Flatpak/ujust plumbing
   - `ghcr.io/ublue-os/brew` — the Homebrew integration

2. **Base image** — the `FROM` line. It defaults to Fedora Silverblue and is the
   only place the base is chosen. `just build` reads the image name and tag from
   it; the Fedora major is read from the base image itself during the build.

3. **Phases** — each build script runs in its own `RUN` block, in the order the
   Containerfile names them. [build/README.md](../../../build/README.md) lists
   them.

## Layout

| Path | Holds |
|---|---|
| `Containerfile` | Image assembly: identity, base image, and phases. |
| `Justfile` | Build, VM, release, and test recipes. |
| `build/` | Build-time scripts: the phases, helpers, and the `.example` catalogue. |
| `custom/brew/` | Brewfiles, installed at runtime. |
| `custom/flatpaks/` | Flatpak preinstall declarations, installed on first boot. |
| `custom/ujust/` | `ujust` recipes. |
| `custom/files/` | System files overlaid onto `/`. |
| `custom/config/` | Per-user config seeded into `/etc/skel/.config/`. |
| `iso/` | Installer ISO and disk-image configuration. |
| `tests/` | `contract/` (interfaces the image must satisfy) and `template/` (this repository's build wiring). |
| `.github/` | Workflows, Renovate config, issue templates. |

## Which skill

| I need to… | Load |
|---|---|
| Understand the repository, or find the right skill | `overview` |
| Fork it and reach a first green build | `onboarding` |
| Add or remove a package, app, or command | `customize` |
| Change the Containerfile, Justfile, or a build phase | `build` |
| Change a workflow, Renovate, or the release model | `ci` |
| Fix something broken, or check before a pull request | `troubleshooting` |
| Check how a tool really behaves before relying on it | `upstream-check` |

## Upstream

The template consumes Project Bluefin's shared infrastructure rather than
copying it:

- `projectbluefin/common` — the shared runtime layer and the lifecycle label
  workflow
- `projectbluefin/actions` — the reusable workflows for image build, promotion,
  sync, PR validation, and Renovate
- `ublue-os/brew` — the Homebrew integration

Changes stay in this repository. `ublue-os/*` is read-only.

## Ampersand

Ampersand is Finpilot with these additions (README lists them for users):

| Path | Holds |
|---|---|
| `build/25-ampersand-packages.sh` … `44-ampersand.sh` | Ampersand's phases, each its own `RUN` block between the package phase and cleanup (`build/README.md`). |
| `build/gnome-extensions.txt`, `build/extension-patches/` | Extensions from extensions.gnome.org and temporary patches for them. |
| `custom/files/` | Ampersand's GNOME defaults (gschema override, dconf keyfiles), keyd config, user services, helper scripts. |
| `custom/brew/*.Brewfile` | Ampersand's app suites, managed by `ujust` suite recipes. |
| `custom/vscode/` | Starter VS Code profiles (`ujust devmode`). |
| `cosign.pub` | The key installed systems check updates against (`ci` skill, Signing). |
| `iso/titanoboa/` | The live installer ISO hook (`build-disk.yml`). |
| `containers/marp-export/` | A helper image for Marp exports, built by `build-marp-export.yml`. |
| `research/gotchas.md` | Where a tool behaved differently from what we assumed. |

The spec (`spec/`) is in Ryan's Ampersand folder, not in this repo.
