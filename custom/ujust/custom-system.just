# vim: set ft=make :
#######################
### custom-system.just
#######################
## System-level commands.
##
## Nothing here runs automatically: image updates and logins never overwrite
## user configuration. This recipe is the explicit, user-invoked way to do it.
## (Finpilot's configure-dev-groups is dropped: `ujust devmode` adds the one
## group Ampersand needs, dialout, and uses Podman's socket instead of docker.)

# Restore the image's default user configuration into this user's home.
[group('System')]
install-config:
    #!/usr/bin/env bash
    set -euo pipefail

    # The defaults live in /etc/skel/.config, which covers every account created
    # after the build. An existing user's own files always win: nothing applies
    # them on login or on an image update, so this is the explicit way to get
    # them back. Files it replaces are backed up beside the original.
    SKEL_CONFIG="${SKEL_CONFIG:-/etc/skel/.config}"
    USER_CONFIG="${USER_CONFIG:-${HOME}/.config}"
    TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"

    bold="$(tput bold 2>/dev/null || printf '\033[1m')"
    normal="$(tput sgr0 2>/dev/null || printf '\033[0m')"

    if [[ ! -d "${SKEL_CONFIG}" ]]; then
        echo "Error: ${SKEL_CONFIG} does not exist" >&2
        exit 1
    fi

    # Collect conflicts first, so the prompt shows the full set before anything
    # is touched.
    conflicts=()
    while IFS= read -r -d '' file; do
        relative="${file#"${SKEL_CONFIG}"/}"
        target="${USER_CONFIG}/${relative}"
        if [[ -e "${target}" || -L "${target}" ]]; then
            conflicts+=("${relative}")
        fi
    done < <(find "${SKEL_CONFIG}" -type f -print0)

    echo "${bold}Re-apply default configuration${normal}"
    echo "  from: ${SKEL_CONFIG}"
    echo "    to: ${USER_CONFIG}"
    if ((${#conflicts[@]})); then
        echo
        echo "Already present, and will be backed up first:"
        printf '  - %s\n' "${conflicts[@]}"
    fi
    echo

    if command -v gum >/dev/null 2>&1; then
        if ! gum confirm "Apply these defaults?"; then
            echo "Cancelled."
            exit 0
        fi
    fi

    backed_up=()
    installed=()
    while IFS= read -r -d '' file; do
        relative="${file#"${SKEL_CONFIG}"/}"
        target="${USER_CONFIG}/${relative}"
        target_dir="$(dirname "${target}")"

        if ! mkdir -p "${target_dir}"; then
            echo "  WARN: cannot create ${target_dir}, skipping ${relative}"
            continue
        fi

        if [[ -e "${target}" || -L "${target}" ]]; then
            backup="${target}.backup.${TIMESTAMP}"
            n=1
            while [[ -e "${backup}" || -L "${backup}" ]]; do
                backup="${target}.backup.${TIMESTAMP}.${n}"
                n=$((n + 1))
            done
            mv "${target}" "${backup}"
            backed_up+=("${backup#"${USER_CONFIG}"/}")
        fi

        cp "${file}" "${target}"
        installed+=("${relative}")
    done < <(find "${SKEL_CONFIG}" -type f -print0)

    echo
    echo "${bold}Applied ${#installed[@]} file(s)${normal}"
    if ((${#backed_up[@]})); then
        echo
        echo "Backed up:"
        printf '  - %s\n' "${backed_up[@]}"
    fi
