# Base and identity

**Source:** `Containerfile` (`FROM` lines, identity `ARG`s),
`build/00-image-info.sh`, `.github/workflows/build-image.yml`

## Purpose

What Ampersand is built from, what it calls itself, and where installed systems
look for updates.

## Current state

| Item | Why it is here |
|---|---|
| `quay.io/fedora-ostree-desktops/silverblue:44` | Base image: Fedora 44 with GNOME. Template default, kept. |
| `ghcr.io/projectbluefin/common` | Shared runtime layer (ujust entry point, first-boot hooks, update policy). Imported into the build context. |
| `ghcr.io/ublue-os/brew` | Homebrew mechanism. Imported into the build context. |
| `ampersand` | Image name: GHCR package, `os-release` `NAME`/`ID`, `image-info.json`. |
| `ghcr.io/messaiga/ampersand` | Published reference, and the update reference baked into `image-info.json`. |

## Decisions

- **Every `FROM` is digest-pinned** — Renovate bumps the digests; nothing
  floats between builds.
- **The repository name is lowercase** (`Messaiga/ampersand`) — the release
  workflows pass it through unlowercased, and registry references must be
  lowercase. See the onboarding skill, step 1.
- **The vendor comes from the repository owner in CI** — the Containerfile's
  `IMAGE_VENDOR="projectbluefin"` is only the local-build fallback.
  `build-image.yml` lowercases it so the baked reference is valid.
- **Updates use `ostree-unverified-image:`** — signatures are enforced at
  promotion to `:stable`, not on the device. The README's "Where the signature
  is checked" explains why; changing this needs key-based signing first.
- **`IMAGE_DESC` is left at the template default** — not worth customizing yet.

## Not included

- `quay.io/fedora-ostree-desktops/base-main`, `centos-bootc`, `hummingbird` —
  the Containerfile's other suggested bases; Ampersand wants a GNOME desktop.
- `common/bluefin/` and `common/nvidia/` — imported but never overlaid;
  `bluefin/` is Bluefin's product opinion, `nvidia/` needs a real driver.

## Inherited

- Fedora Silverblue's package set, kernel and GNOME session — from the
  [Fedora OSTree desktops](https://quay.io/repository/fedora-ostree-desktops/silverblue)
  base.
- `/etc/containers/policy.json`, unmodified — from
  [projectbluefin/common](https://github.com/projectbluefin/common).
