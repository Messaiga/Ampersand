# Ampersand image spec

This folder records **what Ampersand changes on top of its base, and why**. It
is the source for the "What Makes this Raptor Different?" section of the
top-level README, and the place an agent reads before changing a customization.

## What belongs here, and what does not

The repository already states *what* is installed: the Brewfiles, the Flatpak
preinstall files, the build scripts. A spec that restates them drifts. These
files hold what the code cannot say:

- **Intent** — what each domain is for on this image.
- **Decisions** — why an item is present, and why a tempting one is not.
- **Inheritance** — what arrives from the base image, `projectbluefin/common`
  or `ublue-os/brew`, named and linked rather than copied.

Each domain file lists its current items by identifier, so a contract test can
check that the spec and the repository agree. The list is an index into the
code, not a second copy of it.

| Lives in | Answers |
|---|---|
| `spec/` | What is true of this image now, and why |
| `.agents/skills/` | How to do a task in this repository |
| Code under `build/` and `custom/` | Exactly what ships |
| `README.md` | What a user of the image needs to know, drawn from `spec/` |

## Domains

| File | Covers | Feeds README section | Status |
|---|---|---|---|
| [base-and-identity.md](base-and-identity.md) | Base image, name, vendor, update reference, signing posture | intro | planned |
| [packages.md](packages.md) | RPM and COPR packages installed at build time | Added Packages (Build-time) | planned |
| [services.md](services.md) | systemd units enabled or disabled | Configuration Changes | planned |
| [flatpaks.md](flatpaks.md) | Flatpaks preinstalled on first boot | Added Applications → GUI apps | planned |
| [brew.md](brew.md) | Brewfiles and what each installs | Added Applications → CLI tools | planned |
| [ujust.md](ujust.md) | Custom `ujust` recipes | Configuration Changes | planned |
| [config-and-files.md](config-and-files.md) | `custom/config` user defaults and `custom/files` system payloads | Configuration Changes | planned |
| [removed-or-disabled.md](removed-or-disabled.md) | What the image drops, disables, or deliberately leaves out | Removed or Disabled | planned |

Every domain file follows [_template.md](_template.md).

## Keeping it current

A change to a customization updates its domain file **in the same pull
request**. A spec file that disagrees with the repository is a bug in the spec,
not a record of intent; fix whichever side is wrong.
