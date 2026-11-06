#!/usr/bin/env bats
# Contract: spec/ records what this image customizes. Nothing else keeps it in
# step with the repository, so this test does, in both directions: everything
# the build ships is listed in its domain file's "Current state" table, and
# everything that table lists actually ships.
#
# Only the "Current state" table is matched, and only the first backticked
# identifier in each row. "Not included" and the prose are free text.

REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
SPEC="${REPO_ROOT}/spec"
DOMAINS=(base-and-identity packages services flatpaks brew ujust config-and-files removed-or-disabled)

# First backticked identifier of each row in the file's "Current state" table.
spec_items() {
	awk '/^## /{in_state = ($0 == "## Current state")} in_state && /^\| `/' "${SPEC}/$1.md" |
		sed -n 's/^| `\([^`]*\)`.*/\1/p' | LC_ALL=C sort -u
}

# Build scripts the Containerfile actually runs: every build/*.sh except the
# helpers it sources and the validators CI calls.
active_build_scripts() {
	find "${REPO_ROOT}/build" -maxdepth 1 -name '[0-9]*.sh' | LC_ALL=C sort
}

# Preinstalled Flatpaks plus the app groups' Brewfile `flatpak` entries. The
# DX group's Brewfile comes unchanged from Common, so its apps are inherited
# and listed under "Inherited", not here.
shipped_flatpaks() {
	{
		sed -n 's/^\[Flatpak Preinstall \(.*\)\]$/\1/p' "${REPO_ROOT}"/custom/flatpaks/*.preinstall
		sed -n 's/^[[:space:]]*flatpak[[:space:]]\{1,\}"\([^"]*\)".*/\1/p' "${REPO_ROOT}"/custom/brew/*.Brewfile
	} | LC_ALL=C sort -u
}

shipped_recipes() {
	find "${REPO_ROOT}/custom/ujust" -type f -iname '*.just' -exec cat {} + |
		grep -v ':=' | sed -n 's/^\([a-z][a-z0-9-]*\)[^:]*:.*/\1/p' | LC_ALL=C sort -u
}

shipped_brewfiles() {
	find "${REPO_ROOT}/custom/brew" -name '*.Brewfile' -printf '%f\n' | LC_ALL=C sort -u
}

shipped_brew_packages() {
	sed -n 's/^[[:space:]]*\(brew\|cask\)[[:space:]]\+"\([^"]*\)".*/\2/p' "${REPO_ROOT}"/custom/brew/*.Brewfile | LC_ALL=C sort -u
}

shipped_packages() {
	active_build_scripts | while read -r script; do
		grep -v '^[[:space:]]*#' "${script}" |
			sed -n -e 's/^[[:space:]]*dnf5 install -y \(.*\)$/\1/p' \
				-e 's/^[[:space:]]*copr_install_isolated "[^"]*" \(.*\)$/\1/p'
	done | tr ' ' '\n' | sed '/^$/d' | LC_ALL=C sort -u
}

shipped_units() {
	active_build_scripts | while read -r script; do
		grep -v '^[[:space:]]*#' "${script}" |
			sed -n 's/^[[:space:]]*systemctl \(--global \)\{0,1\}\(enable\|disable\|mask\) \([^ ]*\).*/\3/p'
	done | LC_ALL=C sort -u
}

shipped_config_files() {
	(cd "${REPO_ROOT}" && find custom/config custom/files -type f \
		\! -path custom/config/README.md \! -path custom/files/README.md) | LC_ALL=C sort -u
}

# Fails, naming each identifier, when $2 (shipped) and $3 (spec) differ.
assert_agree() {
	local domain=$1 shipped=$2 listed=$3 missing extra
	missing="$(LC_ALL=C comm -23 <(printf '%s\n' "${shipped}" | sed '/^$/d') <(printf '%s\n' "${listed}" | sed '/^$/d'))"
	extra="$(LC_ALL=C comm -13 <(printf '%s\n' "${shipped}" | sed '/^$/d') <(printf '%s\n' "${listed}" | sed '/^$/d'))"
	if [[ -n "${missing}" ]]; then
		printf 'FAIL: shipped but not in spec/%s.md "Current state":\n%s\n' "${domain}" "${missing}" >&2
	fi
	if [[ -n "${extra}" ]]; then
		printf 'FAIL: in spec/%s.md "Current state" but not shipped:\n%s\n' "${domain}" "${extra}" >&2
	fi
	[[ -z "${missing}" && -z "${extra}" ]]
}

@test "spec: every domain file exists, is indexed, and has the template's sections" {
	for domain in "${DOMAINS[@]}"; do
		[ -f "${SPEC}/${domain}.md" ] || { echo "missing spec/${domain}.md" >&2; return 1; }
		grep -qF "(${domain}.md)" "${SPEC}/README.md" || { echo "spec/README.md does not index ${domain}.md" >&2; return 1; }
		for section in Purpose "Current state" Decisions "Not included" Inherited; do
			grep -qx "## ${section}" "${SPEC}/${domain}.md" ||
				{ echo "spec/${domain}.md has no '## ${section}'" >&2; return 1; }
		done
	done
}

@test "spec: flatpaks.md lists exactly the preinstalled and app-group Flatpaks" {
	assert_agree flatpaks "$(shipped_flatpaks)" "$(spec_items flatpaks)"
}

@test "spec: ujust.md lists exactly the custom recipes" {
	assert_agree ujust "$(shipped_recipes)" "$(spec_items ujust)"
}

@test "spec: brew.md lists exactly the Brewfiles and their packages" {
	assert_agree brew "$(printf '%s\n%s\n' "$(shipped_brewfiles)" "$(shipped_brew_packages)" | sed '/^$/d' | LC_ALL=C sort -u)" "$(spec_items brew)"
}

@test "spec: packages.md lists exactly the RPM and COPR packages" {
	assert_agree packages "$(shipped_packages)" "$(spec_items packages)"
}

@test "spec: services.md lists exactly the units the build enables, disables or masks" {
	assert_agree services "$(shipped_units)" "$(spec_items services)"
}

@test "spec: config-and-files.md lists exactly the files under custom/config and custom/files" {
	assert_agree config-and-files "$(shipped_config_files)" "$(spec_items config-and-files)"
}
