# Ampersand recipes. Installed as /usr/share/ublue-os/just/60-custom.just,
# which Bluefin's ujust imports after its own files. A recipe here with the same
# name as a Bluefin one replaces it.

# Install Ampersand's default Flatpaks (replaces Bluefin's list; they also install automatically at boot)
[group('Ampersand')]
install-system-flatpaks $confirm="1":
    #!/usr/bin/env bash
    if [ "$confirm" != 0 ] ; then
        gum confirm "Install Ampersand's default Flatpaks?" || exit 0
    fi
    # Same lists flatpak-preinstall.service applies at boot (/usr/share/flatpak/preinstall.d).
    flatpak preinstall -y

# Install the optional audio production apps (adds the Mixtapes remote)
[group('Ampersand')]
ampersand-install-audio:
    brew bundle --file=/usr/share/ampersand/flatpaks/audio.Brewfile

# Install the optional video and media apps
[group('Ampersand')]
ampersand-install-media:
    brew bundle --file=/usr/share/ampersand/flatpaks/media.Brewfile

# Install the optional gaming apps
[group('Ampersand')]
ampersand-install-gaming:
    brew bundle --file=/usr/share/ampersand/flatpaks/gaming.Brewfile

# Reset your GNOME settings, extensions and shortcuts to Ampersand's defaults
[group('Ampersand')]
ampersand-gnome:
    #!/usr/bin/env bash
    set -euo pipefail
    gum confirm "Reset the settings Ampersand sets (extensions, power, shortcuts, icons...) to its defaults?" || exit 0
    # Every key in Ampersand's override goes back to its default, so this list
    # never needs updating by hand.
    override=/usr/share/glib-2.0/schemas/zz1-ampersand.gschema.override
    schema=""
    while IFS= read -r line; do
        case "${line}" in
            '#'*|'') ;;
            '['*']') schema="${line:1:-1}" ;;
            *=*) gsettings reset "${schema}" "${line%%=*}" || echo "Skipped ${schema} ${line%%=*}" ;;
        esac
    done < "${override}"
    # Ampersand's own custom shortcuts (yours are left alone).
    for path in $(grep -o 'custom-keybindings/ampersand-[a-z-]*' /etc/dconf/db/distro.d/50-ampersand-keybindings); do
        dconf reset -f "/org/gnome/settings-daemon/plugins/media-keys/${path}/"
    done
    echo "Done. Log out and back in for extension changes to take effect."

# Let the Tailscale extension control Tailscale without a password prompt
[group('Ampersand')]
ampersand-tailscale:
    sudo tailscale set --operator="${USER}"

# Switch between ampersand and ampersand-dx (takes effect after a reboot)
[group('Ampersand')]
ampersand-switch-variant:
    #!/usr/bin/env bash
    set -euo pipefail
    current="$(bootc status --format json | jq -r '.status.booted.image.image.image')"
    case "${current}" in
        */ampersand-dx:*) target="${current/ampersand-dx:/ampersand:}" ;;
        */ampersand:*) target="${current/ampersand:/ampersand-dx:}" ;;
        *) echo "Not running an Ampersand image (${current})." >&2; exit 1 ;;
    esac
    gum confirm "Switch to ${target}?" || exit 0
    sudo bootc switch "${target}"
    echo "Reboot to start ${target##*/}."
