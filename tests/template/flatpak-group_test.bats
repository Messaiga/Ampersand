#!/usr/bin/env bats
# Tests for custom/files/usr/libexec/ampersand/flatpak-group.sh, the helper
# behind every `ujust install-<group>` recipe.
#
# The contract (spec/flatpaks.md): with none of the group installed, install
# all of it; with some, offer to install the rest, uninstall what remains, or
# do nothing; with all, say so and offer to uninstall them or do nothing.
# "No", or a dismissed prompt, changes nothing.
#
# flatpak, brew and gum are PATH mocks: nothing touches the host.

SCRIPT="${BATS_TEST_DIRNAME}/../../custom/files/usr/libexec/ampersand/flatpak-group.sh"

setup() {
	WORKDIR="$(mktemp -d)"
	LOG="${WORKDIR}/calls"
	BREWFILE="${WORKDIR}/group.Brewfile"
	mkdir -p "${WORKDIR}/bin"
	: >"${LOG}"
	cat >"${BREWFILE}" <<'EOF'
# A group
brew "tmux"
flatpak "org.example.One"
flatpak "org.example.Two"
  flatpak "org.example.Three" # indented, with a comment
EOF

	cat >"${WORKDIR}/bin/flatpak" <<'MOCK'
#!/usr/bin/bash
echo "flatpak $*" >>"${LOG}"
if [[ "$1" == list ]]; then
	printf '%s\n' ${MOCK_INSTALLED:-}
fi
MOCK
	cat >"${WORKDIR}/bin/brew" <<'MOCK'
#!/usr/bin/bash
echo "brew $*" >>"${LOG}"
exit "${MOCK_BREW_STATUS:-0}"
MOCK
	cat >"${WORKDIR}/bin/gum" <<'MOCK'
#!/usr/bin/bash
echo "gum $*" >>"${LOG}"
[[ "${MOCK_GUM_CHOICE:-}" == dismiss ]] && exit 130
echo "${MOCK_GUM_CHOICE}"
MOCK
	chmod +x "${WORKDIR}"/bin/*
	export LOG
	export PATH="${WORKDIR}/bin:/usr/bin:/bin"
}

teardown() {
	rm -rf "${WORKDIR}"
}

_run() {
	run bash "${SCRIPT}" "Test" "${BREWFILE}"
}

@test "flatpak-group: with none installed, installs the whole group without asking" {
	_run
	[ "${status}" -eq 0 ]
	[[ "${output}" == *"Installing the Test apps:"* ]]
	grep -qx "brew bundle --file ${BREWFILE}" "${LOG}"
	! grep -q '^gum' "${LOG}"
	! grep -q '^flatpak uninstall' "${LOG}"
}

@test "flatpak-group: reads installed apps from the system installation" {
	_run
	grep -qx 'flatpak list --system --app --columns=application' "${LOG}"
}

@test "flatpak-group: with some installed, lists both sides and offers three choices" {
	MOCK_INSTALLED="org.example.One org.unrelated.App" MOCK_GUM_CHOICE=No _run
	[ "${status}" -eq 0 ]
	[[ "${output}" == *"Some Test apps are installed:"*"org.example.One"*"Not installed:"*"org.example.Two"*"org.example.Three"* ]]
	grep -qx 'gum choose --header What now? Install the rest Uninstall what remains No' "${LOG}"
}

@test "flatpak-group: 'Install the rest' bundles the Brewfile" {
	MOCK_INSTALLED="org.example.One" MOCK_GUM_CHOICE="Install the rest" _run
	[ "${status}" -eq 0 ]
	grep -qx "brew bundle --file ${BREWFILE}" "${LOG}"
	! grep -q '^flatpak uninstall' "${LOG}"
}

@test "flatpak-group: 'Uninstall what remains' removes only the installed group apps" {
	MOCK_INSTALLED="org.example.One org.example.Three org.unrelated.App" MOCK_GUM_CHOICE="Uninstall what remains" _run
	[ "${status}" -eq 0 ]
	grep -qx 'flatpak uninstall --system -y org.example.One org.example.Three' "${LOG}"
	! grep -q '^brew' "${LOG}"
}

@test "flatpak-group: with all installed, says so and offers to uninstall them" {
	MOCK_INSTALLED="org.example.One org.example.Two org.example.Three" MOCK_GUM_CHOICE="Uninstall them" _run
	[ "${status}" -eq 0 ]
	[[ "${output}" == *"All 3 Test apps are installed:"* ]]
	grep -qx 'gum choose --header Uninstall them? Uninstall them No' "${LOG}"
	grep -qx 'flatpak uninstall --system -y org.example.One org.example.Two org.example.Three' "${LOG}"
}

@test "flatpak-group: 'No' changes nothing" {
	MOCK_INSTALLED="org.example.One org.example.Two org.example.Three" MOCK_GUM_CHOICE=No _run
	[ "${status}" -eq 0 ]
	[[ "${output}" == *"No changes made."* ]]
	! grep -q '^brew' "${LOG}"
	! grep -q '^flatpak uninstall' "${LOG}"
}

@test "flatpak-group: a dismissed prompt counts as 'No'" {
	MOCK_INSTALLED="org.example.One" MOCK_GUM_CHOICE=dismiss _run
	[ "${status}" -eq 0 ]
	[[ "${output}" == *"No changes made."* ]]
	! grep -q '^brew' "${LOG}"
	! grep -q '^flatpak uninstall' "${LOG}"
}

@test "flatpak-group: without gum, falls back to a numbered menu" {
	rm "${WORKDIR}/bin/gum"
	# A PATH of only the mocks and sed, so a gum on the host cannot be found.
	ln -s "$(command -v sed)" "${WORKDIR}/bin/sed"
	MOCK_INSTALLED="org.example.One"
	export MOCK_INSTALLED
	PATH="${WORKDIR}/bin" run /usr/bin/bash "${SCRIPT}" "Test" "${BREWFILE}" <<<"1"
	[ "${status}" -eq 0 ]
	grep -qx "brew bundle --file ${BREWFILE}" "${LOG}"
}

@test "flatpak-group: a failing install reports a nonzero exit" {
	MOCK_BREW_STATUS=1 _run
	[ "${status}" -ne 0 ]
}

@test "flatpak-group: fails when the Brewfile is missing" {
	run bash "${SCRIPT}" "Test" "${WORKDIR}/nope.Brewfile"
	[ "${status}" -eq 1 ]
	[[ "${output}" == *"Brewfile not found"* ]]
}

@test "flatpak-group: fails when the Brewfile declares no Flatpaks" {
	printf 'brew "tmux"\n' >"${BREWFILE}"
	_run
	[ "${status}" -eq 1 ]
	[[ "${output}" == *"declares no Flatpaks"* ]]
}

@test "flatpak-group: rejects the wrong number of arguments" {
	run bash "${SCRIPT}" "only-one"
	[ "${status}" -eq 2 ]
	[[ "${output}" == *"Usage:"* ]]
}
