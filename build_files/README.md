# build_files

Scripts that run **inside the image build** (anything that needs a command, like installing a package).
Files that only need to *exist* in the image go in `system_files/` instead.

`build.sh` copies `system_files/` into the image, then runs every `NN-name.sh` here in numeric order.
`IMAGE_NAME` (`ampersand` or `ampersand-dx`) is available to every step, so a step can do DX-only work:

```bash
if [[ "${IMAGE_NAME}" == "ampersand-dx" ]]; then
    ...
fi
```

## Steps

| Step | Does |
|---|---|
| `05-image-info.sh` | Points `/usr/share/ublue-os/image-info.json` at Ampersand (name, `ghcr.io/messaiga` image, `stable` tag); the installer ISO reads it |
| `10-gnome-extensions.sh` | Installs the extensions in `gnome-extensions.txt` from extensions.gnome.org (newest release for the image's GNOME; fails if one has none) |
| `20-keyd.sh` | Installs keyd (Super leader key) from COPR and enables it |
| `30-icons.sh` | Installs the Hatter and MoreWaita icon themes from pinned tags |
| `40-custom.sh` | Installs `custom/` (Flatpak lists, Brewfiles, ujust recipes) where Bluefin's tools find them |
| `50-signing.sh` | Trusts Ampersand's signing key (`cosign.pub`) for `ghcr.io/messaiga` in `/etc/containers/policy.json` |
| `90-gnome-defaults.sh` | Compiles the GNOME defaults from `system_files/` and enables the accent-folder service |

The installed extension versions are recorded in `/usr/share/ampersand/gnome-extensions.txt` in the image.
