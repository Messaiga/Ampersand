# custom

Apps and user-facing recipes. `build_files/40-custom.sh` installs them.

| File | Installed to | Used by |
|---|---|---|
| `flatpaks/ampersand.preinstall` | `/usr/share/flatpak/preinstall.d/` | Default Flatpaks, installed automatically at boot (`flatpak-preinstall.service`) |
| `flatpaks/ampersand-dx.preinstall` | same (DX only) | Extra Flatpaks on ampersand-dx |
| `flatpaks/{audio,media,gaming}.Brewfile` | `/usr/share/ampersand/flatpaks/` | `ujust ampersand-install-audio` / `-media` / `-gaming` |
| `brew/ampersand-dx.Brewfile` | `/usr/share/ublue-os/homebrew/preinstall.d/` (DX only) | CLI tools, installed at login by Bluefin's `brew-preinstall` |
| `ujust/ampersand.just` | `/usr/share/ublue-os/just/60-custom.just` | `ujust` (run `ujust` to see the Ampersand group) |

Careful with the `.preinstall` files: removing an app from them uninstalls it from every machine on its next boot. To stop shipping an app without removing it from existing machines, leave it out of a new list only after checking that's what you want.
