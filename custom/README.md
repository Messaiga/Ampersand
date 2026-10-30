# custom

Apps and user-facing recipes. `build_files/40-custom.sh` installs them.

| File | Installed to | Used by |
|---|---|---|
| `flatpaks/ampersand.preinstall` | `/usr/share/flatpak/preinstall.d/` | Default Flatpaks, installed automatically at boot (`flatpak-preinstall.service`) |
| `suites/*.Brewfile` | `/usr/share/ampersand/suites/` | `ujust devmode`, `ai-tools`, `gaming-apps`, `audio-apps`, `media-apps`: install the recommended set, pick, or change what's installed. Format in [`suites/README.md`](suites/README.md) |
| `vscode/` | `/usr/share/ampersand/vscode/` | `ujust devmode` (via `devmode-vscode`, when VS Code is installed): one folder per VS Code profile (`extensions.txt`, optional `settings.json`, `tasks.json`), extensions shared by all profiles in `common-extensions.txt`, and dev container starters copied to `~/Templates` |
| `ujust/ampersand.just` | `/usr/share/ublue-os/just/60-custom.just` | `ujust` (listed under System with Bluefin's recipes) |

Careful with the `.preinstall` files: removing an app from them uninstalls it from every machine on its next boot.

`ujust devmode` sets up VS Code profiles but only adds what's missing: it never overwrites a profile's settings or tasks once they exist, so it's safe to re-run after adding an extension to a list.
