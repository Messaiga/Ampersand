#!/usr/bin/env bats
# Tests for custom/ujust/custom-apps.just recipes:
#   install-default-apps, install-dev-tools, and the Flatpak app-group
#   recipes, which hand a Brewfile to flatpak-group.sh (tested on its own in
#   flatpak-group_test.bats).
#
# Each shebang recipe body is extracted out of the justfile into a standalone
# bash script and run against a PATH mock for brew, so the Brewfile path and
# the recipe's exit status are exercised without touching the host or the
# network.

APPS_JUST="${BATS_TEST_DIRNAME}/../../custom/ujust/custom-apps.just"
BREW_DIR="${BATS_TEST_DIRNAME}/../../custom/brew"
WORKDIR=""
MOCKDIR=""
COMMAND_LOG=""

_extract_recipe() {
    local recipe="$1" out_file="$2"
    awk -v recipe="${recipe}" '
        $0 ~ ("^" recipe "([ ][A-Za-z_]+)*:$") { in_recipe=1; next }
        in_recipe && !found && /^    #!/ { found=1; next }
        found && /^[^[:space:]]/ { exit }
        found { sub(/^    /, ""); print }
    ' "${APPS_JUST}" > "${out_file}"
    chmod +x "${out_file}"
    # Guard against a recipe rename silently producing an empty test subject.
    [ -s "${out_file}" ]
}

setup() {
    WORKDIR="$(mktemp -d)"
    MOCKDIR="${WORKDIR}/bin"
    COMMAND_LOG="${WORKDIR}/commands.log"
    mkdir -p "${MOCKDIR}" "${WORKDIR}/home"
    : > "${COMMAND_LOG}"

    cat > "${MOCKDIR}/brew" <<'MOCK'
#!/usr/bin/bash
echo "brew $*" >> "${COMMAND_LOG}"
exit "${MOCK_BREW_STATUS:-0}"
MOCK
    chmod +x "${MOCKDIR}/brew"

    export COMMAND_LOG
    export HOME="${WORKDIR}/home"
    # A minimal PATH keeps a real brew on the runner from leaking in.
    export PATH="${MOCKDIR}:/usr/bin:/bin"
}

teardown() {
    rm -rf "${WORKDIR}"
}

_run_recipe() {
    local recipe="$1"
    shift
    _extract_recipe "${recipe}" "${WORKDIR}/${recipe}.sh"
    run env PATH="${PATH}" HOME="${HOME}" COMMAND_LOG="${COMMAND_LOG}" "$@" \
        /usr/bin/bash "${WORKDIR}/${recipe}.sh"
}

@test "install-default-apps bundles only the default Brewfile" {
    _run_recipe "install-default-apps"

    [ "${status}" -eq 0 ]
    [ "$(grep -cF "brew bundle" "${COMMAND_LOG}")" -eq 1 ]
    grep -qF "brew bundle --file /usr/share/ublue-os/homebrew/default.Brewfile" "${COMMAND_LOG}"
}

@test "install-dev-tools bundles only the development Brewfile" {
    _run_recipe "install-dev-tools"

    [ "${status}" -eq 0 ]
    [ "$(grep -cF "brew bundle" "${COMMAND_LOG}")" -eq 1 ]
    grep -qF "brew bundle --file /usr/share/ublue-os/homebrew/development.Brewfile" "${COMMAND_LOG}"
}

@test "a failing bundle reports a nonzero exit" {
    _run_recipe "install-default-apps" MOCK_BREW_STATUS=1

    [ "${status}" -ne 0 ]
}

@test "every Brewfile referenced by a recipe is shipped by the image" {
    # Guards against a Brewfile rename that would leave ujust pointing at a path
    # the image never ships. Recipes bundle files the template owns, plus the
    # one Brewfile 10-overlay.sh copies unchanged from Common's bluefin/ tree.
    local referenced name
    referenced="$(grep -o '/usr/share/ublue-os/homebrew/[A-Za-z0-9._-]*\.Brewfile' "${APPS_JUST}" | sort -u)"
    [ -n "${referenced}" ]
    while IFS= read -r path; do
        name="$(basename "${path}")"
        if [[ "${name}" == system-dx-flatpaks.Brewfile ]]; then
            grep -qF "homebrew/${name}" "${BATS_TEST_DIRNAME}/../../build/10-overlay.sh"
        else
            [ -f "${BREW_DIR}/${name}" ]
        fi
    done <<< "${referenced}"
}

_group_recipes() {
    # Only recipe bodies (indented lines) count; the file's header comment names
    # the helper too.
    awk '/^    .*flatpak-group\.sh/ { print recipe } /^[a-z][A-Za-z0-9_-]*:$/ { recipe = substr($0, 1, length($0) - 1) }' "${APPS_JUST}"
}

@test "app-group recipes hand their Brewfile to flatpak-group.sh" {
    local recipe
    while IFS= read -r recipe; do
        _extract_recipe "${recipe}" "${WORKDIR}/${recipe}.sh"
        grep -qE '^exec /usr/bin/bash /usr/libexec/ampersand/flatpak-group\.sh "[^"]+" /usr/share/ublue-os/homebrew/[A-Za-z0-9._-]+\.Brewfile$' "${WORKDIR}/${recipe}.sh"
    done < <(_group_recipes)
    [ "$(_group_recipes | wc -l)" -eq 6 ]
}

@test "every custom Brewfile of flatpak entries has an app-group recipe" {
    # A group Brewfile no recipe installs is unreachable from ujust.
    local brewfile
    for brewfile in "${BREW_DIR}"/*.Brewfile; do
        grep -q '^[[:space:]]*flatpak[[:space:]]' "${brewfile}" || continue
        grep -qE "flatpak-group\.sh \"[^\"]+\" /usr/share/ublue-os/homebrew/$(basename "${brewfile}")\$" "${APPS_JUST}" ||
            { echo "no recipe for $(basename "${brewfile}")" >&2; return 1; }
    done
}

@test "the group helper ships through custom/files" {
    [ -x "${BATS_TEST_DIRNAME}/../../custom/files/usr/libexec/ampersand/flatpak-group.sh" ]
}

@test "every custom-apps recipe declares a just group" {
    # ujust renders its menu by group; an ungrouped recipe disappears from it.
    local ungrouped
    ungrouped="$(awk '
        /^\[group\(/ { grouped=1; next }
        /^[a-z][A-Za-z0-9_-]*([ ][A-Za-z_]+)*:$/ {
            if (!grouped) print $0
            grouped=0
            next
        }
        /^[^[:space:]]/ { grouped=0 }
    ' "${APPS_JUST}")"
    [ -z "${ungrouped}" ]
}
