#!/usr/bin/env bash
# Install, complete or remove one Flatpak app group.
#
# Usage: flatpak-group.sh <label> <brewfile>
#
# Every `ujust install-<group>` recipe calls this with its group's Brewfile.
# The Brewfile's `flatpak "<app-id>"` lines are the group; anything else in it
# is left to `brew bundle`. What happens depends on what is already installed
# system-wide:
#
#   none installed  install all of them
#   some installed  offer: install the rest / uninstall what remains / No
#   all installed   say so, then offer: uninstall them / No
#
# "No", or dismissing the prompt, changes nothing and exits 0.
# spec/flatpaks.md records this behaviour; change both together.

set -euo pipefail

if [[ $# -ne 2 ]]; then
	echo "Usage: $0 <label> <brewfile>" >&2
	exit 2
fi
label=$1
brewfile=$2

if [[ ! -r "${brewfile}" ]]; then
	echo "Brewfile not found: ${brewfile}" >&2
	exit 1
fi

mapfile -t apps < <(sed -n 's/^[[:space:]]*flatpak[[:space:]]\{1,\}"\([^"]*\)".*/\1/p' "${brewfile}")
if [[ ${#apps[@]} -eq 0 ]]; then
	echo "${brewfile} declares no Flatpaks." >&2
	exit 1
fi

declare -A installed=()
while IFS= read -r app_id; do
	[[ -n "${app_id}" ]] && installed["${app_id}"]=1
done < <(flatpak list --system --app --columns=application)

present=()
missing=()
for app_id in "${apps[@]}"; do
	if [[ -n "${installed[${app_id}]:-}" ]]; then
		present+=("${app_id}")
	else
		missing+=("${app_id}")
	fi
done

# Prints the chosen option. gum is installed at build time; select is the
# fallback for a shell without it. A dismissed prompt is reported as "No".
choose() {
	local header=$1 option
	shift
	if command -v gum >/dev/null 2>&1; then
		gum choose --header "${header}" "$@" || echo "No"
		return
	fi
	PS3="${header} "
	select option in "$@"; do
		if [[ -n "${option}" ]]; then
			echo "${option}"
			return
		fi
	done
	echo "No"
}

list() {
	printf '  - %s\n' "$@"
}

install_all() {
	if ! command -v brew >/dev/null 2>&1; then
		echo "brew is not available; check brew-setup.service." >&2
		exit 1
	fi
	# brew bundle skips what is installed, so this also installs "the rest".
	brew bundle --file "${brewfile}"
}

uninstall_present() {
	flatpak uninstall --system -y "${present[@]}"
}

if [[ ${#present[@]} -eq 0 ]]; then
	echo "Installing the ${label} apps:"
	list "${missing[@]}"
	install_all
	exit 0
fi

if [[ ${#missing[@]} -eq 0 ]]; then
	echo "All ${#apps[@]} ${label} apps are installed:"
	list "${present[@]}"
	choice="$(choose "Uninstall them?" "Uninstall them" "No")"
else
	echo "Some ${label} apps are installed:"
	list "${present[@]}"
	echo "Not installed:"
	list "${missing[@]}"
	choice="$(choose "What now?" "Install the rest" "Uninstall what remains" "No")"
fi

case "${choice}" in
"Install the rest") install_all ;;
"Uninstall them" | "Uninstall what remains") uninstall_present ;;
*) echo "No changes made." ;;
esac
