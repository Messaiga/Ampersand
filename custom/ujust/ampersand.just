# Ampersand recipes, listed under System with Bluefin's own. Installed as
# /usr/share/ublue-os/just/60-custom.just; build_files/40-custom.sh makes ujust
# import it before Bluefin's files, so a recipe here with the same name as a
# Bluefin one replaces it. [private] ones still run but aren't listed.

# Pick what to set up: voice typing, Tailscale, local AI, developer tools and more
[group('System')]
setup-desktop:
    #!/usr/bin/env bash
    set -euo pipefail
    STATE_DIR="${HOME}/.local/state/ampersand/setup"
    mkdir -p "${STATE_DIR}"
    # id | label (no commas) | ticked by default | ujust recipe that does it
    steps=(
        "tailscale|Tailscale: let the top-bar extension control it|on|_tailscale-operator"
        "speed-of-sound|Voice typing with Speed of Sound (Super+D)|on|_speed-of-sound"
        "local-ai|Local AI assistant (downloads a ~6 GB model; Super+G)|off|toggle-local-ai enable"
        "devmode|Developer tools: VS Code and containers and editors|off|devmode"
        "ai-tools|AI apps and coding agents|off|ai-tools"
        "phone|Phone Mirror (pair the phone in GSConnect first)|off|setup-phone"
    )
    labels=() selected=()
    for step in "${steps[@]}"; do
        IFS='|' read -r id label default _ <<<"${step}"
        if [[ -e "${STATE_DIR}/${id}" ]]; then
            label="${label} [done]"
        elif [[ "${default}" == on ]]; then
            selected+=("${label}")
        fi
        labels+=("${label}")
    done
    picks="$(gum choose --no-limit --header "Set up Ampersand (space to tick, enter to start):" \
        --selected="$(IFS=,; echo "${selected[*]}")" "${labels[@]}")" || exit 0
    failed=()
    for step in "${steps[@]}"; do
        IFS='|' read -r id label _ recipe <<<"${step}"
        grep -qF "${label}" <<<"${picks}" || continue
        gum style --bold "==> ${label}"
        # shellcheck disable=SC2086 # recipe may carry an argument
        if ujust ${recipe}; then
            touch "${STATE_DIR}/${id}"
        else
            failed+=("${label}")
        fi
    done
    if (( ${#failed[@]} )); then
        printf 'Not finished: %s\n' "${failed[@]}"
        echo "Run ujust setup-desktop again to retry."
        exit 1
    fi
    echo "All set. Run ujust setup-desktop any time to add more."

# Developer tools (VS Code, containers, editors, dev apps): install a recommended set, or change what's installed
[group('System')]
devmode:
    @ujust _suite devmode "Developer tools" _devmode-after

# AI apps and coding agents (Claude, Goose, Antigravity and more): install a recommended set, or change what's installed
[group('System')]
ai-tools:
    @ujust _suite ai-tools "AI tools" _ai-tools-after

# Gaming apps (Steam, Bottles, Lutris, ProtonPlus): install a recommended set, or change what's installed
[group('System')]
gaming-apps:
    @ujust _suite gaming "Gaming apps"

# Audio production apps (Ardour, LMMS, MuseScore and more): install a recommended set, or change what's installed
[group('System')]
audio-apps:
    @ujust _suite audio "Audio apps"

# Video and media apps (OBS, Kdenlive, VLC and more): install a recommended set, or change what's installed
[group('System')]
media-apps:
    @ujust _suite media "Media apps"

# Install the default Flatpaks now (they also install automatically at boot)
[group('System')]
install-system-flatpaks $confirm="1":
    #!/usr/bin/env bash
    if [ "$confirm" != 0 ] ; then
        gum confirm "Install Ampersand's default Flatpaks?" || exit 0
    fi
    # Same lists flatpak-preinstall.service applies at boot (/usr/share/flatpak/preinstall.d).
    flatpak preinstall -y

# Shared by the app suites above. The list is custom/suites/<suite>.Brewfile:
# lines with a "# Name: description" comment are the menu, "(recommended)"
# marks the default set. after: a recipe to run when something was installed.
[private]
_suite suite title after="":
    #!/usr/bin/env bash
    set -euo pipefail
    LIST="/usr/share/ampersand/suites/{{ suite }}.Brewfile"
    brews="$(brew list --formula -1 2>/dev/null || true)"
    casks="$(brew list --cask -1 2>/dev/null || true)"
    flatpaks="$(flatpak list --app --columns=application 2>/dev/null || true)"
    declare -A entry_of=()
    labels=() recommended=() installed=()
    while IFS= read -r entry; do
        label="${entry#*# }"
        label="${label% (recommended)}"
        entry_of["${label}"]="${entry%% #*}"
        labels+=("${label}")
        if [[ "${entry}" == *"(recommended)" ]]; then recommended+=("${label}"); fi
        id="$(cut -d'"' -f2 <<<"${entry}")"
        case "${entry%% *}" in
            brew) have="${brews}" ;;
            cask) have="${casks}" ;;
            *) have="${flatpaks}" ;;
        esac
        if grep -qxF "${id##*/}" <<<"${have}"; then installed+=("${label}"); fi
    done < <(grep -E '^(brew|cask|flatpak) .*# ' "${LIST}")
    pick() { # pick <header> <preselected...>
        local header="$1"; shift
        gum choose --no-limit --height 25 --header "${header}" \
            --selected="$(IFS=,; echo "$*")" "${labels[@]}"
    }

    if (( ${#installed[@]} == 0 )); then
        echo "{{ title }}: none installed. The recommended set is:"
        printf '  %s\n' "${recommended[@]}"
        case "$(gum choose "Install the recommended set" "Let me pick" "No")" in
            Install*) picks="$(printf '%s\n' "${recommended[@]}")" ;;
            Let*) picks="$(pick "Pick the {{ title }} to install (space to tick):" "${recommended[@]}")" || exit 0 ;;
            *) exit 0 ;;
        esac
    else
        echo "{{ title }}: installed now:"
        printf '  %s\n' "${installed[@]}"
        case "$(gum choose "Change the selection" "Remove everything" "No")" in
            Change*) picks="$(pick "Tick what you want; untick to remove:" "${installed[@]}")" || exit 0 ;;
            Remove*) picks="" ;;
            *) exit 0 ;;
        esac
    fi

    add=() remove=()
    for label in "${labels[@]}"; do
        wanted=0 has=0
        if grep -qxF "${label}" <<<"${picks}"; then wanted=1; fi
        if printf '%s\n' "${installed[@]}" | grep -qxF "${label}"; then has=1; fi
        if (( wanted && ! has )); then add+=("${label}"); fi
        if (( has && ! wanted )); then remove+=("${label}"); fi
    done
    if (( ! ${#add[@]} && ! ${#remove[@]} )); then echo "Nothing to change."; exit 0; fi
    if (( ${#add[@]} )); then echo "Install:"; printf '  %s\n' "${add[@]}"; fi
    if (( ${#remove[@]} )); then echo "Remove:"; printf '  %s\n' "${remove[@]}"; fi
    gum confirm "Go ahead?" || exit 0

    if (( ${#remove[@]} )); then
        apps=()
        for label in "${remove[@]}"; do
            line="${entry_of[${label}]}"
            id="$(cut -d'"' -f2 <<<"${line}")"
            case "${line%% *}" in
                brew) brew uninstall "${id##*/}" ;;
                cask) brew uninstall --cask "${id##*/}" ;;
                *) apps+=("${id}") ;;
            esac
        done
        if (( ${#apps[@]} )); then
            delete=()
            if gum confirm --default=false "Also delete these apps' settings and data?"; then delete=(--delete-data); fi
            flatpak uninstall -y "${delete[@]}" "${apps[@]}"
        fi
    fi
    if (( ${#add[@]} )); then
        brewfile="$(mktemp --suffix=.Brewfile)"
        trap 'rm -f "${brewfile}"' EXIT
        grep -E '^tap ' "${LIST}" >"${brewfile}" || true
        for label in "${add[@]}"; do echo "${entry_of[${label}]}" >>"${brewfile}"; done
        brew bundle --file="${brewfile}"
        if [[ -n "{{ after }}" ]]; then ujust "{{ after }}"; fi
    fi
    echo "Done. Run this again any time to change the {{ title }}."

# devmode, after installing: group membership and the VS Code starter profiles.
[private]
_devmode-after:
    #!/usr/bin/env bash
    set -euo pipefail
    # Serial devices (Arduino, USB-serial) need the dialout group; this asks for your password.
    if ! id -nG | grep -qw dialout; then
        pkexec bash -c "
            grep -q '^dialout:' /etc/group || grep '^dialout:' /usr/lib/group >>/etc/group
            usermod -aG dialout $(id -un)
        "
        echo "Log out and back in to use serial devices (dialout group)."
    fi
    # There is no Docker daemon (or docker group): the Docker CLI talks to
    # Podman's Docker-compatible socket, for your user only.
    if command -v docker >/dev/null; then
        systemctl --user enable --now podman.socket
        env_file="${XDG_CONFIG_HOME:-${HOME}/.config}/environment.d/50-ampersand-docker.conf"
        if [[ ! -e "${env_file}" ]]; then
            mkdir -p "$(dirname "${env_file}")"
            echo "DOCKER_HOST=unix://${XDG_RUNTIME_DIR}/podman/podman.sock" >"${env_file}"
            echo "Log out and back in so docker uses Podman (DOCKER_HOST is in ${env_file})."
        fi
    fi
    if command -v code >/dev/null; then
        if pgrep -x code >/dev/null; then
            echo "VS Code is open: close it and run ujust devmode-vscode for the starter profiles."
        else
            ujust devmode-vscode
        fi
    fi
    echo "For an Ubuntu VM (like WSL), run: ujust setup-lima"

# ai-tools, after installing: Goose starts with Bluefin's config, which adds the
# read-only Linux diagnostics tools.
[private]
_ai-tools-after:
    #!/usr/bin/env bash
    set -euo pipefail
    goose_config="${XDG_CONFIG_HOME:-${HOME}/.config}/goose/config.yaml"
    if brew list -1 2>/dev/null | grep -q goose && [[ ! -e "${goose_config}" && -f /usr/share/ublue-os/goose/config.yaml ]]; then
        install -Dm0644 /usr/share/ublue-os/goose/config.yaml "${goose_config}"
    fi

# Reset your GNOME settings, extensions and shortcuts to Ampersand's defaults
[group('System')]
reset-desktop:
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
    # Extension settings: every key in Ampersand's dconf file.
    path=""
    while IFS= read -r line; do
        case "${line}" in
            '#'*|'') ;;
            '['*']') path="/${line:1:-1}/" ;;
            *=*) dconf reset "${path}${line%%=*}" ;;
        esac
    done < /etc/dconf/db/distro.d/51-ampersand-extensions
    echo "Done. Log out and back in for extension changes to take effect."

# Lets the Tailscale extension control Tailscale without a password prompt (setup-desktop)
[private]
_tailscale-operator:
    sudo tailscale set --operator="${USER}"

# Local AI assistant (RamaLama model + Newelle, Super+G): shows its state, then enable or disable
[group('System')]
toggle-local-ai action="":
    #!/usr/bin/env bash
    set -euo pipefail
    SERVICE=ampersand-ai
    QUADLET="${HOME}/.config/containers/systemd/${SERVICE}.container"
    NEWELLE=io.github.qwersyk.Newelle
    newelle_gsettings() { flatpak run --command=gsettings "${NEWELLE}" "$@"; }

    model=""
    if [[ -f "${QUADLET}" ]]; then
        model="$(grep -oE 'hf://[^ ]+' "${QUADLET}" | head -n1 || true)"
        state="enabled ($(systemctl --user is-active "${SERVICE}.service" 2>/dev/null || true)), model ${model##*/}"
    else
        state="disabled"
    fi
    echo "Local AI: ${state}"
    action="{{ action }}"
    [[ -n "${action}" ]] || action="$(gum choose Enable Disable Cancel)"

    case "${action,,}" in
    disable)
        systemctl --user stop "${SERVICE}.service" 2>/dev/null || true
        rm -f "${QUADLET}"
        systemctl --user daemon-reload
        newelle_gsettings reset "${NEWELLE}" language-model 2>/dev/null || true
        newelle_gsettings reset "${NEWELLE}" llm-settings 2>/dev/null || true
        if [[ -n "${model}" ]] && gum confirm --default=false "Also delete the downloaded model (${model##*/}, several GB)?"; then
            ramalama rm "${model}" || true
        fi
        echo "Local AI is off."
        exit 0
        ;;
    enable) ;;
    *) exit 0 ;;
    esac

    # Pick the model by memory: 8B needs ~6 GB, 4B ~3.3 GB.
    ram_gb="$(awk '/MemTotal/ {print int($2 / 1048576)}' /proc/meminfo)"
    if (( ram_gb >= 24 )); then
        MODEL=hf://ggml-org/Qwen3-VL-8B-Instruct-GGUF
    elif (( ram_gb >= 12 )); then
        MODEL=hf://ggml-org/Qwen3-VL-4B-Instruct-GGUF
    else
        echo "Only ${ram_gb} GB of memory: local AI needs 12 GB or more." >&2
        exit 1
    fi
    gum confirm "Download ${MODEL##*/} (several GB) and run it in the background?" || exit 0

    command -v ramalama >/dev/null || brew install ramalama
    ramalama pull "${MODEL}"
    # A Quadlet is a systemd unit that runs a container; RamaLama writes it for us
    # with the right GPU image. It only listens on this machine (127.0.0.1).
    mkdir -p "$(dirname "${QUADLET}")"
    ramalama serve --name "${SERVICE}" --port 8080 --webui off \
        --generate "quadlet:$(dirname "${QUADLET}")" "${MODEL}"
    systemctl --user daemon-reload
    systemctl --user start "${SERVICE}.service"

    # Point Newelle at it (OpenAI-compatible API).
    flatpak info "${NEWELLE}" >/dev/null 2>&1 || flatpak install -y flathub "${NEWELLE}"
    newelle_gsettings set "${NEWELLE}" language-model 'openai'
    newelle_gsettings set "${NEWELLE}" llm-settings \
        "{\"openai\": {\"endpoint\": \"http://127.0.0.1:8080/v1\", \"api\": \"local\", \"model\": \"${SERVICE}\"}}"
    echo "Local AI is ready: press Super+G."

# Prepares Speed of Sound for voice typing with Super+D (setup-desktop)
[private]
_speed-of-sound:
    #!/usr/bin/env bash
    set -euo pipefail
    APP=io.speedofsound.SpeedOfSound
    flatpak info "${APP}" >/dev/null 2>&1 || flatpak install -y flathub "${APP}"
    # Start without a window at login; Super+D triggers it over D-Bus.
    flatpak run --command=gsettings "${APP}" set "${APP}" stay-hidden-on-activation true
    echo "Speed of Sound will open now. On first run:"
    echo "  1. Click 'Allow remote interaction' so it can type into other apps."
    echo "  2. Pick and download a voice model in Preferences."
    echo "Then close it; it starts hidden at every login. Press Super+D to dictate."
    flatpak run "${APP}" &

# One-time setup for Phone Mirror: pair with your phone and set up the MacroDroid trigger
[group('System')]
setup-phone:
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
    echo "Done. Open Phone Mirror from the app grid."

# Creates the starter VS Code profiles and dev container templates (run by devmode)
[private]
devmode-vscode:
    #!/usr/bin/env bash
    set -euo pipefail
    SRC=/usr/share/ampersand/vscode
    USER_DIR="${HOME}/.config/Code/User"
    STORAGE="${USER_DIR}/globalStorage/storage.json"
    if ! command -v code >/dev/null || [[ ! -d "${SRC}" ]]; then
        echo "VS Code isn't installed yet. Run: ujust devmode" >&2
        exit 1
    fi
    if pgrep -x code >/dev/null; then
        echo "Close VS Code first (it rewrites its profile list on exit)." >&2
        exit 1
    fi

    # VS Code has no command to create an empty profile, so add any missing ones
    # to its profile list. Each profile lives in User/profiles/<random id>/.
    # VS Code reads this list at start-up (a plain location is relative to
    # User/profiles), so it works before VS Code has ever been opened.
    mkdir -p "$(dirname "${STORAGE}")"
    [[ -s "${STORAGE}" ]] || echo '{}' > "${STORAGE}"
    cp "${STORAGE}" "${STORAGE}.bak"
    for dir in "${SRC}"/profiles/*/; do
        name="$(basename "${dir}")"
        if ! jq -e --arg n "${name}" '.userDataProfiles // [] | any(.name == $n)' "${STORAGE}" >/dev/null; then
            id="$(od -An -N4 -tx4 /dev/urandom | tr -d ' ')"
            jq --arg n "${name}" --arg id "${id}" '.userDataProfiles = ((.userDataProfiles // []) + [{location: $id, name: $n}])' \
                "${STORAGE}" > "${STORAGE}.tmp" && mv "${STORAGE}.tmp" "${STORAGE}"
            echo "Created profile ${name}"
        fi
    done

    for dir in "${SRC}"/profiles/*/; do
        name="$(basename "${dir}")"
        # Stored as a folder name, or as a full URI by some VS Code versions.
        location="$(jq -r --arg n "${name}" '.userDataProfiles[] | select(.name == $n) | .location
            | if type == "string" then . else .path | split("/") | last end' "${STORAGE}")"
        profile_dir="${USER_DIR}/profiles/${location}"
        mkdir -p "${profile_dir}"

        # Starter settings and tasks. Never overwrites a file you've changed.
        # An empty file counts as missing (an earlier failed run may have left one).
        if [[ -f "${dir}settings.json" && ! -s "${profile_dir}/settings.json" ]]; then
            cp "${dir}settings.json" "${profile_dir}/settings.json"
        fi
        if [[ -f "${dir}tasks.json" && ! -s "${profile_dir}/tasks.json" ]]; then
            cp "${dir}tasks.json" "${profile_dir}/tasks.json"
        fi

        echo "Installing extensions for ${name}..."
        grep -hEv '^\s*(#|$)' "${SRC}/common-extensions.txt" "${dir}extensions.txt" | while read -r ext; do
            code --profile "${name}" --install-extension "${ext}" >/dev/null
        done
    done

    # Marp exports mount your fonts folder, so make sure it exists.
    mkdir -p "${HOME}/.local/share/fonts"

    # Dev container starters, e.g. ~/Templates/devcontainer-python.
    templates="$(xdg-user-dir TEMPLATES 2>/dev/null || echo "${HOME}/Templates")"
    mkdir -p "${templates}"
    for dir in "${SRC}"/devcontainers/*/; do
        target="${templates}/devcontainer-$(basename "${dir}")"
        [[ -e "${target}" ]] || cp -r "${dir}" "${target}"
    done
    echo "Done. Pick a profile in VS Code: File > New Window with Profile."
    echo "Dev container starters are in ${templates}."

#-------------- Bluefin recipes Ampersand replaces or hides --------------#

# Bluefin's Developer Mode switch (rebases to -dx): Ampersand's devmode installs apps instead.
[private]
toggle-devmode:
    @ujust devmode

# Would switch this machine to Bluefin's testing image, off Ampersand.
[private]
toggle-testing:
    @echo "Not available on Ampersand: it would switch this machine to Bluefin's testing image."

[private]
bluefin-apps:
    @ujust install-system-flatpaks

# Both install Bluefin's whole AI tools list; ai-tools lets you pick.
[private]
bluespeed:
    @ujust ai-tools

[private]
install-ai-tools:
    @ujust ai-tools

# Hidden from the list but still work, by running Bluefin's own recipe.
[private]
setup-lima:
    @just --justfile /usr/share/ublue-os/just/system.just setup-lima

[private]
setup-vms:
    @just --justfile /usr/share/ublue-os/just/system.just setup-vms

[private]
toggle-vms:
    @just --justfile /usr/share/ublue-os/just/system.just toggle-vms

[private]
install-jetbrains-toolbox:
    @just --justfile /usr/share/ublue-os/just/apps.just install-jetbrains-toolbox

[private]
jetbrains-toolbox:
    @just --justfile /usr/share/ublue-os/just/apps.just install-jetbrains-toolbox

[private]
install-opentabletdriver:
    @just --justfile /usr/share/ublue-os/just/apps.just install-opentabletdriver

[private]
install-asus:
    @just --justfile /usr/share/ublue-os/just/apps.just install-asus
