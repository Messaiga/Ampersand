#!/usr/bin/env bash
# Prints the Flatpaks named in Flatpak .preinstall files, one per line, in the
# form Titanoboa's Flatpak list expects (ID, or ID//BRANCH for non-stable branches).
# Usage: flatpak-list.sh FILE.preinstall...
set -euo pipefail

awk '
    /^\[Flatpak Preinstall / { if (id) print_ref(); id = $3; sub(/\]$/, "", id); branch = "stable"; next }
    /^Branch=/ { branch = substr($0, 8) }
    END { if (id) print_ref() }
    function print_ref() { print (branch == "stable" ? id : id "//" branch) }
' "$@" | sort -u
