---
name: ampersand-upstream-check
description: Use before writing or changing any Ampersand spec item, build script, recipe or default that depends on how a tool behaves, and when testing such a feature, to check it against the tool's official docs and the real image.
---

# Ampersand upstream check

Goal: the spec and the code say only what the tools actually do. Every claim about
tool behaviour gets a source link or a test result before it goes into the spec or a PR.

## Pinned versions (update when the base moves)

- Base: `ghcr.io/ublue-os/bluefin:stable` = **Bluefin Classic** (GNOME 50.x, Fedora 44 on 2026-10-30).
  Read docs.projectbluefin.io **/classic/**, not /dakota/ (a different image).
- Read the docs for the version **in the image**, not the newest:
  `rpm -q gnome-shell flatpak bootc keyd`, `just --version`, `gum --version`,
  `brew --version`, `distrobox --version`, `code --version`, `ramalama version`.

## Workflow

1. **List the tools** the feature touches: every file it ships and every command it runs.
2. **Read sources in this order**, stop at the first that answers:
   1. The real system: the built image or the VM (`gsettings`, files on disk, `--help`).
   2. Upstream source at the pinned version: `ublue-os/bluefin` (`build_files/`, `system_files/`, `Justfile`),
      `projectbluefin/iso`, `ublue-os/image-template`, the tool's own repo/man page.
   3. The tool's official docs (links below).
   4. Universal Blue Discourse, GitHub issues.
   5. Blog posts or memory: never enough on their own; mark *assumed* and test.
3. **Label each spec item**: *verified* (tested on the bench, date + image), *documented* (link),
   or *assumed* (neither yet; test first).
4. **Test**: run the universal checklist, then the checklist of **every** tool from step 1.
5. **Log mismatches** as one line in `research/gotchas.md`:
   `YYYY-MM-DD · tool · what we assumed → what is true · source`.
6. If unsure how a tool works, ask Ryan or test in the VM. Don't guess.

## Universal checklist (every feature)

- [ ] Each behaviour claim has a link or test result; labels set.
- [ ] CI build green (includes `bootc container lint` and our build checks).
- [ ] **Fresh user** in the VM gets the default. **Existing user** (bench) keeps own values until `ujust reset-desktop`.
- [ ] Re-run is safe: a second run changes nothing and doesn't fail.
- [ ] Undo works (toggle off, reset, uninstall, or `sudo bootc rollback`).
- [ ] Still works after `sudo bootc upgrade` + reboot.
- [ ] Test log in `research/` with date and `bootc status` image digest.

## Combining checklists

A feature uses the union of its tools' checklists. Examples:

| Feature | Checklists |
|---|---|
| `ujust setup-desktop` | just/ujust, gum, systemd (setup offer), Tailscale, Flatpak (Speed of Sound) |
| Suite managers (`devmode`, `ai-tools`…) | just/ujust, gum, Homebrew, Flatpak, VS Code (devmode) |
| Super+key shortcuts | keyd, GSettings/dconf, GNOME extensions (Tiling Shell, Simple Taskbar, Search Light) |
| Extension defaults (dconf 51-…) | GSettings/dconf, GNOME extensions |
| Speed of Sound hidden autostart | XDG autostart, Flatpak |
| Accent folder icons | systemd user units, XDG icon theme, GSettings |
| Local AI toggle | just/ujust, RamaLama, Podman, systemd, Flatpak (Newelle), keyd/GSettings (Super+G) |
| Phone Mirror | adb/scrcpy, GSConnect, MacroDroid, XDG desktop entry |
| Marp export | VS Code tasks, Podman, Marp CLI, GitHub Actions (image build) |
| ISO install | Titanoboa, Flatpak preinstall, bootc, signing, Secure Boot |

## Tools

### Bluefin / Universal Blue / image-template
Docs: https://docs.projectbluefin.io/classic/ · https://docs.projectbluefin.io/administration/ ·
https://docs.projectbluefin.io/bluefin-dx/ · https://github.com/ublue-os/bluefin ·
https://universal-blue.org/documentation.html · https://github.com/ublue-os/image-template · https://github.com/projectbluefin/iso
- [ ] The Bluefin file/recipe we override or rely on still exists at that path in the current image.
- [ ] Our change layers on top (later number, `import?`, override file) rather than editing Bluefin's file, unless the spec says so.
- [ ] After a Bluefin bump, diff the Bluefin files we touch (e.g. `00-entry.just`, `user-setup.hooks.d/`).

### just / ujust
Docs: https://just.systems/man/en/ · imports and override order https://just.systems/man/en/imports.html ·
attributes https://just.systems/man/en/attributes.html · shebang recipes https://just.systems/man/en/shebang-recipes.html
- [ ] `just --unstable --fmt --check -f custom/ujust/ampersand.just` passes (`just check`).
- [ ] Every feature used exists in the image's `just --version`.
- [ ] `ujust --list` shows the recipe under **System**; `[private]` ones are hidden but run when typed.
- [ ] Overriding a Bluefin recipe: at the same import depth the **earlier** import wins; `ujust --show <name>` prints ours.
- [ ] Shebang recipes start with `set -euo pipefail`; runs as the normal user, `sudo` only where needed.

### gum
Docs: https://github.com/charmbracelet/gum (README is incomplete: check `gum <cmd> --help` in the image)
- [ ] Every flag used appears in `gum choose --help` / `gum confirm --help` in the image.
- [ ] Esc/Ctrl+C exits cleanly with no changes.
- [ ] Labels have no commas (`--selected` takes a comma list).

### bootc / rpm-ostree / image build
Docs: https://bootc.dev/bootc/ · upgrades https://containers.github.io/bootc/upgrades.html ·
filesystem https://bootc.dev/bootc/bootc-filesystem.7.html · lint https://www.mankier.com/8/bootc-container-lint ·
https://coreos.github.io/rpm-ostree/ · Containerfile https://github.com/containers/common/blob/main/docs/Containerfile.5.md ·
dnf5 copr https://dnf5.readthedocs.io/en/latest/dnf5_plugins/copr.8.html
- [ ] No content shipped in `/var` (applied only on first install); `/etc` is 3-way merged, so a user-edited file there won't update.
- [ ] Layered RPM: `rpm -q <pkg>` in the image; COPR repo disabled after the build.
- [ ] VM: `bootc status` shows `ghcr.io/messaiga/ampersand:stable`; `sudo bootc upgrade`, reboot, `sudo bootc rollback` all work.

### Image signing
Docs: https://docs.sigstore.dev/cosign/verifying/verify/ ·
policy https://github.com/containers/image/blob/main/docs/containers-policy.json.5.md ·
registries.d https://github.com/containers/image/blob/main/docs/containers-registries.d.5.md
- [ ] `cosign verify --key cosign.pub ghcr.io/messaiga/ampersand:stable` passes.
- [ ] `/etc/containers/policy.json` has `sigstoreSigned` for `ghcr.io/messaiga` with our `keyPath`; cosign signatures need `matchRepository`/`exactRepository` if `signedIdentity` is set.
- [ ] `registries.d` sets `use-sigstore-attachments: true`; `bootc switch --enforce-container-sigpolicy` succeeds.

### GitHub Actions / Renovate
Docs: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax · https://docs.renovatebot.com/ ·
https://docs.renovatebot.com/config-validation/
- [ ] Cron is UTC and matches spec/02; actions pinned.
- [ ] `npx --yes --package renovate -- renovate-config-validator` passes after editing `renovate.json5`.

### ISO, VM and Secure Boot
Docs: https://github.com/ublue-os/titanoboa · https://github.com/osbuild/image-builder-action ·
https://github.com/lcp/mokutil (man/) · https://libvirt.org/kbase/secureboot.html
- [ ] VM uses OVMF with Secure Boot; `mokutil --sb-state` says enabled; MOK prompt as documented.
- [ ] Apps present on first boot offline; web installer used; `bootc status` tracks our image after install.

### GSettings / dconf (GNOME defaults)
Docs: https://docs.gtk.org/gio/class.Settings.html · overrides https://www.mankier.com/1/glib-compile-schemas ·
keyfiles https://help.gnome.org/admin/system-admin-guide/stable/dconf-keyfiles.html.en ·
profiles https://help.gnome.org/admin/system-admin-guide/stable/dconf-custom-defaults.html.en ·
schema source: https://gitlab.gnome.org/GNOME/gsettings-desktop-schemas, …/mutter, …/gnome-shell, …/gnome-settings-daemon
(GitLab may block fetchers: read the XML in the image at `/usr/share/glib-2.0/schemas/` instead)
- [ ] Key exists in the image: `gsettings list-keys <schema> | grep -x <key>`; type/range: `gsettings range <schema> <key>`.
- [ ] Override file sorts after Bluefin's (higher `nn_`/name wins); no other override sets the same key differently.
- [ ] `glib-compile-schemas` prints no warning for our file (without `--strict` a bad file is silently dropped).
- [ ] dconf keyfile: db is in `/etc/dconf/profile/user`; `dconf update` ran; values are GVariant syntax.
- [ ] Fresh user: `gsettings get` / `dconf read` returns our value.

### GNOME Shell extensions
Docs: https://gjs.guide/extensions/ · metadata https://gjs.guide/extensions/overview/anatomy.html ·
schemas https://gjs.guide/extensions/development/preferences.html · https://extensions.gnome.org/ ·
each extension's repo (linked from its EGO page): `schemas/*.gschema.xml` at the installed release
(versions in `/usr/share/ampersand/gnome-extensions.txt`)
- [ ] `metadata.json` `shell-version` lists the image's GNOME major (build gate).
- [ ] Every key we set is in that release's gschema XML (`gsettings list-keys org.gnome.shell.extensions.<name>`).
- [ ] `gnome-extensions info <uuid>` shows ACTIVE, not ERROR/OUT OF DATE; `journalctl --user -b -g <uuid>` clean.
- [ ] On version bump: diff the gschema XML for renamed/removed keys.

### keyd
Docs: https://github.com/rvaiya/keyd · man page https://github.com/rvaiya/keyd/blob/master/docs/keyd.scdoc
- [ ] `sudo keyd check` passes; `systemctl status keyd` active.
- [ ] `sudo keyd monitor` shows the expected events; tap Super = Overview, hold 0.3 s + key = shortcut.

### XDG files (MIME, autostart, desktop entries, icon themes)
Docs: https://specifications.freedesktop.org/mime-apps-spec/latest/file.html ·
https://specifications.freedesktop.org/autostart-spec/latest/ · https://specifications.freedesktop.org/desktop-entry-spec/latest/ ·
https://specifications.freedesktop.org/icon-theme-spec/latest/
- [ ] `desktop-file-validate` passes for shipped `.desktop` files.
- [ ] MIME: `xdg-mime query default <type>` gives the intended app (user `~/.config/mimeapps.list` wins over `/etc/xdg/gnome-mimeapps.list`).
- [ ] Autostart: runs at login; user can disable it with a same-named file `Hidden=true`.
- [ ] Icons: every `Inherits=` theme is installed; missing icons fall back as designed.

### systemd user units
Docs: https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html ·
https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html ·
https://www.freedesktop.org/software/systemd/man/latest/systemctl.html
- [ ] `systemd-analyze verify` on the unit is clean; enabled with `systemctl --global enable`.
- [ ] Fresh user: `systemctl --user status <unit>` ran/active as intended; no failures in `journalctl --user -u <unit>`.

### Flatpak
Docs: https://docs.flatpak.org/en/latest/ · https://docs.flatpak.org/en/latest/flatpak-command-reference.html ·
preinstall https://man7.org/linux/man-pages/man1/flatpak-preinstall.1.html · https://flathub.org
- [ ] Each ID exists: `flatpak remote-info flathub <id>`.
- [ ] Preinstall: `flatpak preinstall` syncs (installs **and removes**) to the vendor list; a user uninstall isn't reinstalled.
  Test any entry removal in the VM first.
- [ ] After boot: `flatpak list --app --columns=application` matches the list; `flatpak-preinstall.service` succeeded.
- [ ] Overrides/permissions: `flatpak override --show <id>`, `flatpak info --show-permissions <id>`.

### Homebrew / Brewfiles
Docs: https://docs.brew.sh/ · https://docs.brew.sh/Brew-Bundle-and-Brewfile · https://formulae.brew.sh/ ·
https://github.com/ublue-os/homebrew-tap
- [ ] Each entry exists: `brew info <formula>` / `brew info --cask <tap>/<cask>`.
- [ ] After install: `brew bundle check --file=<Brewfile>` passes.
- [ ] Never run `brew bundle cleanup` against a suite Brewfile (it removes everything not listed).

### Distrobox (Bluefin ships it; Ampersand doesn't use it yet)
Docs: https://distrobox.it/ · https://distrobox.it/usage/distrobox-create/ · https://distrobox.it/usage/distrobox-assemble/ ·
https://distrobox.it/usage/distrobox-export/ · https://github.com/89luca89/distrobox
- [ ] Manifest keys match the assemble docs (`image`, `init`, `additional_packages`, `exported_apps`, `exported_bins`, `init_hooks`, `replace`).
- [ ] Exported app appears in the app grid; `distrobox-export --app <app> --delete` removes it.
- [ ] Container home choice (`--home`) matches the spec, so dotfiles don't leak into the host home.

### Podman
Docs: https://docs.podman.io/en/latest/ · https://docs.podman.io/en/latest/markdown/podman-run.1.html
- [ ] Runs rootless as the user; bind mounts use `:z` (shared) or `:Z` (private) as intended.
- [ ] No SELinux denials (`sudo ausearch -m avc -ts recent`).

### VS Code and Dev Containers
Docs: profiles https://code.visualstudio.com/docs/configure/profiles · CLI https://code.visualstudio.com/docs/configure/command-line ·
settings https://code.visualstudio.com/docs/configure/settings · tasks https://code.visualstudio.com/docs/debugtest/tasks ·
variables https://code.visualstudio.com/docs/reference/variables-reference ·
dev containers https://code.visualstudio.com/docs/devcontainers/containers · https://containers.dev/implementors/json_reference/ ·
Podman setup https://docs.projectbluefin.io/bluefin-dx/ · https://marketplace.visualstudio.com/vscode
- [ ] Each extension ID exists on the Marketplace.
- [ ] `code --list-extensions --profile <name>` matches `extensions.txt`. A misspelled `--profile` silently creates an empty profile.
- [ ] Each settings key exists: Command Palette → *Preferences: Open Default Settings (JSON)*.
- [ ] Profiles live under `~/.config/Code/User/profiles/` (folder name is not the profile name).
- [ ] Dev container: *Reopen in Container* works with Podman; container extensions show inside, not on the host.

### Marp CLI
Docs: https://github.com/marp-team/marp-cli
- [ ] Each VS Code task exports PDF, PPTX and editable PPTX (`--pptx-editable` is experimental and needs LibreOffice Impress).
- [ ] Fonts render; output opens in LibreOffice.

### RamaLama and Newelle
Docs: https://github.com/containers/ramalama · https://github.com/containers/ramalama/blob/main/docs/ramalama-serve.1.md ·
https://github.com/qwersyk/Newelle/wiki
- [ ] Service passes `--port` (README and man page disagree on the auto range) and listens on 127.0.0.1 only.
- [ ] `curl -s http://127.0.0.1:<port>/v1/models` answers; Newelle answers a question.
- [ ] Idle memory checked (`systemctl --user status <unit>`); toggle off frees it.

### Phone: adb, scrcpy, GSConnect, MacroDroid
Docs: https://developer.android.com/tools/adb#wireless-adb-android-11 · https://github.com/Genymobile/scrcpy/blob/master/doc/connection.md ·
https://github.com/GSConnect/gnome-shell-extension-gsconnect/wiki/CLI-Scripting · https://wiki.macrodroid.com/wiki/
- [ ] Every `adb` subcommand used appears in `adb --help` in the image (Android docs show `adb mdns track-services`).
- [ ] Phone and laptop on the same Wi-Fi; mDNS finds `_adb-tls-connect`; `scrcpy -s <ip:port>` mirrors.
- [ ] Wireless debugging is off again after scrcpy exits (check on the phone).

### Tailscale
Docs: https://tailscale.com/kb/1080/cli
- [ ] `tailscale set --operator=$USER` applied; the top-bar extension toggles without sudo.

### chezmoi (deferred)
Docs: https://www.chezmoi.io/user-guide/command-overview/ · https://www.chezmoi.io/reference/

### Shell scripts (all recipes, build steps, libexec)
Docs: https://www.shellcheck.net/wiki/ · https://jqlang.org/manual/
- [ ] `shellcheck` and `bash -n` clean on every changed script.
- [ ] `jq` filters tested against a real copy of the JSON they read.
