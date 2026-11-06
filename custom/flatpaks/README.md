# Flatpak preinstall

Declarations here are copied into the image at `/usr/share/flatpak/preinstall.d/`
and read on first boot by `flatpak-preinstall.service`, which installs each app
from Flathub. Nothing is embedded in the image or the ISO.

## Files

- `default.preinstall` — the Flathub apps installed on first boot
- `flatpark.preinstall` — the FlatPark apps installed on first boot

Apps a user opts into are not here: they are app groups in `custom/brew/`.

## Format

An INI file, one section per app:

```ini
[Flatpak Preinstall org.mozilla.Thunderbird]
Branch=stable
```

Keys: `Branch` (default `master`; use `stable`), `Install` (default true),
`IsRuntime` (default false), and `CollectionID` (only for a remote that needs
one).

Two gotchas:

- The parser is GKeyFile. Comments must start with `#`; a `;` line is a syntax
  error, and flatpak discards the entire file when one line is malformed.
- `just validate-flatpaks` checks every section for a non-empty `Branch=` key
  and confirms the app exists on Flathub at that branch. CI runs it too.

## Adding one

Append a section to `default.preinstall`, or add another `.preinstall` file. Find
the ID with `flatpak search`, or on [Flathub](https://flathub.org/). Then list it
in `spec/flatpaks.md`; the contract test fails until it is there.

## Apps from another remote

A preinstall file cannot name a remote: flatpak installs each app from
whichever configured remote carries it. So the file name records the intent.
`<remote>.preinstall` is validated against `tests/fixtures/<remote>.flatpakrepo`
instead of Flathub, which is how `flatpark.preinstall` is checked against
FlatPark. The image must also ship that remote; FlatPark's comes from Common.

## First boot

The Flathub remote comes from `/etc/flatpak/remotes.d/flathub.flatpakrepo`, which
the build fetches and checks against the sha256 pinned in `build/10-overlay.sh`
(the descriptor carries the `Url=` and `GPGKey=` every Flatpak is verified
against), so there is nothing to add by hand. `tests/fixtures/flathub.flatpakrepo`
is the pinned copy, and `build/validate-flatpaks.sh` adds the remote from it
rather than the live URL; refresh the fixture and the sha256 together if Flathub
ever rotates it.

`flatpak-preinstall.service` needs the network. When it cannot reach Flathub it
logs a warning, installs nothing, and **still exits successfully**, so it does
not retry that boot. If the first boot happened before Wi-Fi was configured,
reboot once you are online and it will install.
