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

# Set up the local AI assistant: a model served by RamaLama, used by Newelle (Super then G). "undo" removes it
[group('Ampersand')]
ampersand-local-ai action="setup":
    #!/usr/bin/env bash
    set -euo pipefail
    # "auto" = the one-time run at first login (ampersand-local-ai-firstrun.service).
    STATE="${HOME}/.local/state/ampersand/local-ai-done"
    SERVICE=ampersand-ai
    QUADLET_DIR="${HOME}/.config/containers/systemd"
    NEWELLE=io.github.qwersyk.Newelle
    newelle_gsettings() { flatpak run --command=gsettings "${NEWELLE}" "$@"; }
    mkdir -p "$(dirname "${STATE}")"

    if [[ "{{ action }}" == "undo" ]]; then
        systemctl --user stop "${SERVICE}.service" 2>/dev/null || true
        rm -f "${QUADLET_DIR}/${SERVICE}.container"
        systemctl --user daemon-reload
        newelle_gsettings reset "${NEWELLE}" language-model 2>/dev/null || true
        newelle_gsettings reset "${NEWELLE}" llm-settings 2>/dev/null || true
        touch "${STATE}" # so the first-login run doesn't set it up again
        echo "Local AI removed. Downloaded models stay until you run: ramalama rm <model> (see: ramalama list)"
        exit 0
    fi

    # Pick the model by memory: 8B needs ~6 GB, 4B ~3.3 GB.
    ram_gb="$(awk '/MemTotal/ {print int($2 / 1048576)}' /proc/meminfo)"
    if (( ram_gb >= 24 )); then
        MODEL=hf://ggml-org/Qwen3-VL-8B-Instruct-GGUF
    elif (( ram_gb >= 12 )); then
        MODEL=hf://ggml-org/Qwen3-VL-4B-Instruct-GGUF
    else
        echo "Only ${ram_gb} GB of memory: skipping local AI (needs 12 GB or more)."
        touch "${STATE}"
        exit 0
    fi

    if [[ "{{ action }}" != "auto" ]]; then
        gum confirm "Download ${MODEL##*/} (several GB) and run it in the background?" || exit 0
    fi

    command -v ramalama >/dev/null || brew install ramalama
    ramalama pull "${MODEL}"
    # A Quadlet is a systemd unit that runs a container; RamaLama writes it for us
    # with the right GPU image. It only listens on this machine (127.0.0.1).
    mkdir -p "${QUADLET_DIR}"
    ramalama serve --name "${SERVICE}" --port 8080 --webui off \
        --generate "quadlet:${QUADLET_DIR}" "${MODEL}"
    systemctl --user daemon-reload
    systemctl --user start "${SERVICE}.service"

    # Point Newelle at it (OpenAI-compatible API). Needs Newelle installed, which
    # happens at boot; if it isn't there yet, the first-login run tries again next login.
    if ! flatpak info "${NEWELLE}" >/dev/null 2>&1; then
        echo "Newelle isn't installed yet; run this again once it is."
        exit 0
    fi
    newelle_gsettings set "${NEWELLE}" language-model 'openai'
    newelle_gsettings set "${NEWELLE}" llm-settings \
        "{\"openai\": {\"endpoint\": \"http://127.0.0.1:8080/v1\", \"api\": \"local\", \"model\": \"${SERVICE}\"}}"
    touch "${STATE}"
    echo "Local AI is ready: press Super, then G."

# Prepare Speed of Sound for voice typing with Super then D (runs hidden at login)
[group('Ampersand')]
ampersand-setup-speed-of-sound:
    #!/usr/bin/env bash
    set -euo pipefail
    APP=io.speedofsound.SpeedOfSound
    flatpak info "${APP}" >/dev/null 2>&1 || flatpak install -y flathub "${APP}"
    # Start without a window at login; Super then D triggers it over D-Bus.
    flatpak run --command=gsettings "${APP}" set "${APP}" stay-hidden-on-activation true
    echo "Speed of Sound will open now. On first run:"
    echo "  1. Click 'Allow remote interaction' so it can type into other apps."
    echo "  2. Pick and download a voice model in Preferences."
    echo "Then close it; it starts hidden at every login. Press Super, then D to dictate."
    flatpak run "${APP}" &

# One-time setup for Phone Mirror: pair with your phone and set up the MacroDroid trigger
[group('Ampersand')]
ampersand-phone-setup:
    #!/usr/bin/env bash
    set -euo pipefail
    CONFIG="${XDG_CONFIG_HOME:-${HOME}/.config}/ampersand/phone.conf"
    command -v scrcpy >/dev/null || brew install scrcpy

    echo "1/4 GSConnect: pick your phone (pair it in GSConnect first if it isn't listed)."
    mapfile -t ids < <(gsettings get org.gnome.Shell.Extensions.GSConnect devices | grep -oE "'[^']+'" | tr -d "'")
    (( ${#ids[@]} )) || { echo "No GSConnect devices found." >&2; exit 1; }
    choices=()
    for id in "${ids[@]}"; do
        name="$(gsettings get "org.gnome.Shell.Extensions.GSConnect.Device:/org/gnome/shell/extensions/gsconnect/device/${id}/" name | tr -d "'")"
        choices+=("${name} (${id})")
    done
    pick="$(gum choose "${choices[@]}")"
    device="${pick##*(}"; device="${device%)}"

    echo "2/4 Pairing: on the phone, open Developer options > Wireless debugging >"
    echo "    'Pair device with pairing code'."
    ip_port="$(gum input --placeholder 'IP address & port shown on the phone, e.g. 192.168.1.20:37123')"
    code="$(gum input --placeholder 'Six-digit pairing code')"
    adb pair "${ip_port}" "${code}"
    echo "    Now enter the IP address & port from the main Wireless debugging screen."
    connect="$(gum input --placeholder 'e.g. 192.168.1.20:41234')"
    adb connect "${connect}"
    serial="$(adb -s "${connect}" get-serialno)"

    echo "3/4 MacroDroid needs permission to switch Wireless Debugging on (one time):"
    adb -s "${connect}" shell pm grant com.arlosoft.macrodroid android.permission.WRITE_SECURE_SETTINGS
    adb -s "${connect}" shell settings put global adb_wifi_enabled 0 || true
    adb disconnect "${connect}" >/dev/null || true

    phrase="ampersand-$(head -c 6 /dev/urandom | od -An -tx1 | tr -d ' \n')"
    mkdir -p "$(dirname "${CONFIG}")"
    printf 'GSCONNECT_DEVICE=%q\nPHONE_SERIAL=%q\nPING_PHRASE=%q\n' "${device}" "${serial}" "${phrase}" > "${CONFIG}"
    chmod 600 "${CONFIG}"

    echo "4/4 In MacroDroid, create a macro:"
    echo "    Trigger: Notification received, app 'KDE Connect', text contains: ${phrase}"
    echo "    Action:  System setting > Global > adb_wifi_enabled = 1"
    echo "Done. Open 'Phone Mirror' or press Super, then K."
