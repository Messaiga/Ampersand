# Ampersand

Ryan's opinionated GNOME desktop: a [bootc](https://github.com/bootc-dev/bootc)
image built the way Bluefin itself is built, from
[projectbluefin/finpilot](https://github.com/projectbluefin/finpilot). The base
is Fedora Silverblue 44 (GNOME 50), plus the shared layer from
[`projectbluefin/common`](https://github.com/projectbluefin/common) (ujust,
first-boot setup, update tooling), Homebrew from
[`ublue-os/brew`](https://github.com/ublue-os/brew), and Ampersand's own files.

It is built to be driven by hand or by an agent: `AGENTS.md` and the skills in
`.agents/skills/` are the procedures (Claude Code reads them through `CLAUDE.md`
and `.claude/skills`).

## What Makes this Raptor Different?

Ampersand is based on Fedora Silverblue + Common's shared layer, like
Finpilot. It does not use Common's `bluefin/` layer, so Bluefin's own defaults
are not inherited; the ones Ampersand wants are spelled out here.

### Added Packages (Build-time)

- `adw-gtk3-theme`, `keyd` (COPR `alternateved/keyd`), `tailscale`
- GNOME Shell extensions from extensions.gnome.org (`build/gnome-extensions.txt`):
  the set Bluefin enabled (AppIndicator, Bazaar Integration, Blur my Shell,
  Caffeine, Gradia, GSConnect, Logo Menu, Search Light) and Ampersand's own
  (Simple Taskbar, Tiling Shell, Just Perfection, Auto Accent Colour, ChromaLeon,
  audio panel extensions, …)
- Hatter and MoreWaita icon themes

### Added Applications (Runtime)

- **GUI apps (Flatpak)**: `custom/flatpaks/ampersand.preinstall`, Bazaar included
- **App suites (Homebrew + Flatpak)**, each a pick list with a recommended set:
  `ujust devmode`, `ai-tools`, `gaming-apps`, `audio-apps`, `media-apps`

### Removed or Disabled

- The RPMs Bluefin also removes from Silverblue: Firefox (it's a Flatpak here),
  GNOME Software (Bazaar replaces it), `podman-docker`, Yelp, … (`build/25-ampersand-packages.sh`)

### Configuration Changes

- GNOME defaults and extension settings (`custom/files/`): taskbar instead of
  dock, light theme with accent colour from the wallpaper, Super+key app
  shortcuts with a one-shot Super key (keyd), no idle blank or AC suspend
- `ujust setup-desktop` (offered at first login), `toggle-local-ai`,
  `setup-phone`, `reset-desktop`
- Updates only accept images signed with this repository's key

_Last updated: 2026-10-30_

## Releases

| Branch   | Image tag         | Audience                       |
| -------- | ----------------- | ------------------------------ |
| `main`   | `:stable-testing` | The test VM                    |
| `stable` | `:stable`         | The ThinkPad                   |

Merging to `main` publishes `ghcr.io/messaiga/ampersand:stable-testing`; the
promotion PR that follows publishes the same digest as `:stable` when merged.
Promotion verifies the keyless cosign signature on the testing image before it
reports ready, and refuses to promote once `main` has moved past the commit the
promotion PR was built from.

> **Known gap:** the promotion gate checks the digest and the signature only. It
> runs no end-to-end tests, so `release/ready` means "signed and unmodified",
> not "functionally validated". Test `:stable-testing` in the VM first.

Renovate keeps the Silverblue, Common and Brew digests and the actions current.
A Fedora major bump (Silverblue 45 / GNOME 51) is a deliberate `FROM` change.

## Image signing

Ampersand deviates from Finpilot here. Every image is signed twice:

- **keyless** (GitHub OIDC), as Finpilot does, which the promotion gate checks;
- **with this repository's cosign key** (`SIGNING_SECRET` secret, public half in
  `cosign.pub`), which is **verified on the device**: `build/44-ampersand.sh`
  merges a `sigstoreSigned` scope for `ghcr.io/messaiga` into Common's
  `/etc/containers/policy.json`, `custom/files/etc/containers/registries.d/`
  makes clients fetch the signatures, and `image-info.json` uses the
  `ostree-image-signed:` transport. `bootc upgrade` refuses an image this key
  didn't sign. `tests/contract/image-signing_test.bats` holds the pieces together.

```bash
cosign verify --key cosign.pub ghcr.io/messaiga/ampersand:stable
```

The key pair was made once with `COSIGN_PASSWORD="" cosign generate-key-pair`;
`cosign.key` went into the `SIGNING_SECRET` secret and is kept offline. Never
commit it.

## Installing

The installer ISO (and a qcow2 VM disk) comes from the **Build disk images**
workflow: Actions tab → Run workflow → pick `stable` or `stable-testing`, then
download from the run's Artifacts. It is a Titanoboa live ISO like Bluefin's: a
live desktop with the web installer and the default Flatpaks on the ISO. There
is no Secure Boot key to enrol: Ampersand runs Fedora's signed kernel.
Finpilot's own `just build-iso` (bootc-image-builder) still works locally.

Switching a machine that already runs Ampersand (it trusts the key already):

```bash
sudo bootc switch --enforce-container-sigpolicy ghcr.io/messaiga/ampersand:stable-testing
sudo systemctl reboot
```

From any other image, switch once without `--enforce-container-sigpolicy`, then
again with it after the reboot. Then, as your user: `ujust setup-desktop`.

First boot unpacks Homebrew and installs the declared Flatpaks; both need a
network connection. Check them with `systemctl status brew-setup.service` and
`systemctl status flatpak-preinstall.service`.

## Local testing

```bash
just build            # build the container image
just build-qcow2      # build a QCOW2 disk image
just run-vm-qcow2     # boot it in a VM
just lint             # shellcheck
just check            # Justfile syntax
just test-unit        # the bats suite
```

## Troubleshooting

[The `troubleshooting` skill](.agents/skills/troubleshooting/SKILL.md) covers
build, CI, and runtime failures symptom-first; `research/gotchas.md` logs where
a tool behaved differently from what we expected.

## Learn more

- [Finpilot](https://github.com/projectbluefin/finpilot), the template this follows
- [Project Bluefin contributing guide](https://docs.projectbluefin.io/contributing/)
- [bootc](https://containers.github.io/bootc/)
