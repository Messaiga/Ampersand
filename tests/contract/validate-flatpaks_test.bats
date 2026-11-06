#!/usr/bin/env bats
# Tests for build/validate-flatpaks.sh.
#
# All runs use a fake flatpak binary, never the host's. The contract under
# test: every line must be blank, a '#' comment, a [Flatpak Preinstall <app-id>]
# header, or a key=value pair; every such section must declare a non-empty
# Branch= (an empty one fails closed); every app-id is passed to
# `flatpak remote-info` as data, as <app-id>//<branch>, so an unresolvable
# branch fails; and an empty discovery result fails closed instead of
# passing vacuously. A <remote>.preinstall with a pinned fixture resolves on
# that remote; Brewfile `flatpak "<app-id>"` entries resolve on Flathub.
#
# Run with: bats tests/contract/validate-flatpaks_test.bats

SCRIPT="${BATS_TEST_DIRNAME}/../../build/validate-flatpaks.sh"

setup() {
    unset FLATPAK_USER_DIR
    WORKDIR="$(mktemp -d)"
    FIXTURES="${WORKDIR}/flatpaks"
    CALLS="${WORKDIR}/calls"
    mkdir -p "${FIXTURES}" "${WORKDIR}/bin"
    : > "${CALLS}"
    MOCK_ENV_CALLS="${WORKDIR}/env_calls"
    : > "${MOCK_ENV_CALLS}"
    cat > "${WORKDIR}/bin/flatpak" <<'MOCK'
#!/usr/bin/bash
printf '%s\n' "$*" >> "${CALLS}"
printf 'FLATPAK_USER_DIR=%s\n' "${FLATPAK_USER_DIR:-}" >> "${MOCK_ENV_CALLS}"
case "$1" in
    remote-add)
        ;;
    remote-info)
        # $1=remote-info $2=--user $3=<remote> $4=<app-id>//<branch>, or a
        # bare <app-id> for a Brewfile entry, which brew installs unbranched.
        [[ $# -eq 4 ]] || exit 99
        # Like flatpak's ref parser, reject a branch containing whitespace.
        if [[ "${4#*//}" =~ [[:space:]] ]]; then
            echo "error: Invalid branch ${4#*//}" >&2
            exit 1
        fi
        case " ${MOCK_REMOTE_FAILURES:-} " in
            *" ${4%%//*} "*)
                echo 'error: remote-info failed' >&2
                exit 42
                ;;
        esac
        case " ${MOCK_BRANCH_FAILURES:-} " in
            *" ${4#*//} "*)
                echo 'error: No remote refs found for branch' >&2
                exit 43
                ;;
        esac
        ;;
    *) echo "unexpected flatpak operation: $*" >&2; exit 99 ;;
esac
MOCK
    chmod +x "${WORKDIR}/bin/flatpak"
    export CALLS
    export MOCK_ENV_CALLS
    export PATH="${WORKDIR}/bin:/usr/bin:/bin"
}

teardown() {
    rm -rf "${WORKDIR}"
}

@test "validator passes a well-formed preinstall file" {
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
[Flatpak Preinstall org.gnome.Calculator]
Branch=stable
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"PASS: ${FIXTURES}/base.preinstall: org.gnome.Calculator (stable)"* ]]
    [[ "${output}" == *"1 preinstall files, 1 app checks, 0 failures."* ]]
}

@test "validator fails closed on a missing Branch= key" {
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
[Flatpak Preinstall org.gnome.Calculator]
[Flatpak Preinstall org.gnome.TextEditor]
Branch=stable
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"FAIL: ${FIXTURES}/base.preinstall: org.gnome.Calculator: missing Branch= key"* ]]
    # The well-formed app in the same file is still checked and reported.
    [[ "${output}" == *"PASS: ${FIXTURES}/base.preinstall: org.gnome.TextEditor (stable)"* ]]
}

@test "validator fails closed on an empty Branch= value" {
    # Regression: an empty `Branch=` used to satisfy /^Branch=/ and pass,
    # letting flatpak resolve against the remote default branch instead of
    # failing closed. See projectbluefin/finpilot#504.
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
[Flatpak Preinstall org.gnome.Calculator]
Branch=
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"FAIL: ${FIXTURES}/base.preinstall: org.gnome.Calculator: missing Branch= key"* ]]
}

@test "validator fails closed on a whitespace-only Branch= value" {
    # Whitespace-only is still empty for the END check, so it fails closed.
    printf '[Flatpak Preinstall org.gnome.Calculator]\nBranch=   \n' > "${FIXTURES}/base.preinstall"
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"FAIL: ${FIXTURES}/base.preinstall: org.gnome.Calculator: missing Branch= key"* ]]
}

@test "validator accepts key-side whitespace around the = (GKeyFile strips it)" {
    # GKeyFile strips the whitespace around the key and the `=` before
    # comparing, so `Branch = stable` is the key Branch and must not be
    # reported as missing. See projectbluefin/finpilot#509.
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
[Flatpak Preinstall org.gnome.Calculator]
Branch = stable
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"PASS: ${FIXTURES}/base.preinstall: org.gnome.Calculator (stable)"* ]]
}

@test "validator preserves trailing whitespace in the Branch= value (GKeyFile does)" {
    # GKeyFile strips only leading whitespace from the value, so
    # `Branch=stable ` names the branch "stable " (with the trailing space),
    # which flatpak cannot resolve. The branch is now checked on the remote,
    # so this fails instead of resolving against the default branch and
    # passing. See projectbluefin/finpilot#513.
    printf '[Flatpak Preinstall org.gnome.Calculator]\nBranch=stable \n' > "${FIXTURES}/base.preinstall"
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 1 ]
    # bash's %q renders a trailing space as a backslash-escape, not quoted.
    [[ "${output}" == *"FAIL: ${FIXTURES}/base.preinstall: org.gnome.Calculator: not on flathub at branch stable\\  (exit 1)"* ]]
    run grep -c '^remote-info --user flathub org.gnome.Calculator//stable $' "${CALLS}"
    [ "${output}" = "1" ]
}

@test "validator takes the last Branch= of a duplicate (GKeyFile last-wins)" {
    # For a duplicate key GKeyFile uses the last value, not the first, so the
    # later `Branch=stable` must win over the earlier `Branch=old`. See
    # projectbluefin/finpilot#509.
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
[Flatpak Preinstall org.gnome.Calculator]
Branch=old
Branch=stable
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"PASS: ${FIXTURES}/base.preinstall: org.gnome.Calculator (stable)"* ]]
}

@test "validator fails closed when the last of duplicate Branch= is empty" {
    # GKeyFile last-wins also means an empty final value fails closed, even
    # though an earlier value was non-empty. See projectbluefin/finpilot#509.
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
[Flatpak Preinstall org.gnome.Calculator]
Branch=stable
Branch=
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"FAIL: ${FIXTURES}/base.preinstall: org.gnome.Calculator: missing Branch= key"* ]]
}

@test "validator fails when the Branch value does not exist on the remote" {
    # Regression (projectbluefin/finpilot#513): Branch= was only echoed in
    # the PASS line, so a non-empty but nonexistent branch (e.g. Branch=nope)
    # passed because remote-info was called with the app-id alone and
    # resolved against the remote default branch. remote-info is now called
    # with <app-id>//<branch>, so a missing branch fails.
    export MOCK_BRANCH_FAILURES="nope"
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
[Flatpak Preinstall org.gnome.Calculator]
Branch=nope
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"FAIL: ${FIXTURES}/base.preinstall: org.gnome.Calculator: not on flathub at branch nope (exit 43)"* ]]
}

@test "validator fails when an app is not on flathub" {
    export MOCK_REMOTE_FAILURES="com.example.Missing"
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
[Flatpak Preinstall com.example.Missing]
Branch=stable
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"FAIL: ${FIXTURES}/base.preinstall: com.example.Missing: not on flathub at branch stable (exit 42)"* ]]
}

@test "validator fails closed when the directory has no preinstall files" {
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"No .preinstall files found"* ]]
}

@test "validator fails closed when the directory does not exist" {
    run bash "${SCRIPT}" "${FIXTURES}/nope"
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"Flatpak directory does not exist"* ]]
}

@test "validator ensures the flathub remote in an isolated FLATPAK_USER_DIR and passes branch as data" {
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
[Flatpak Preinstall org.gnome.Calculator]
Branch=stable
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 0 ]
    # The remote is added from the checked-in fixture, never the live URL: the
    # whole point of #493 is that the descriptor is pinned, not fetched.
    run grep -c '^remote-add --user --if-not-exists flathub .*fixtures/flathub.flatpakrepo$' "${CALLS}"
    [ "${output}" = "1" ]
    run grep -c '^remote-add --user --if-not-exists flathub https://dl.flathub.org' "${CALLS}"
    [ "${output}" = "0" ]
    run grep -c '^remote-info --user flathub org.gnome.Calculator//stable$' "${CALLS}"
    [ "${output}" = "1" ]
    # Ensure FLATPAK_USER_DIR was exported to a subdirectory of the validator's workdir
    run grep '^FLATPAK_USER_DIR=.*/flatpak$' "${MOCK_ENV_CALLS}"
    [ "${status}" -eq 0 ]
    [ "${#lines[@]}" -ge 2 ]
    # Ensure the isolated directory is distinct from the test's own workdir
    run grep "^FLATPAK_USER_DIR=${WORKDIR}" "${MOCK_ENV_CALLS}"
    [ "${status}" -ne 0 ]
}

@test "validator overrides pre-existing FLATPAK_USER_DIR with temporary isolation dir" {
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
[Flatpak Preinstall org.gnome.Calculator]
Branch=stable
EOF
    FLATPAK_USER_DIR="/host/user/flatpak" run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 0 ]
    run grep '^FLATPAK_USER_DIR=/host/user/flatpak$' "${MOCK_ENV_CALLS}"
    [ "${status}" -ne 0 ]
    run grep '^FLATPAK_USER_DIR=.*/flatpak$' "${MOCK_ENV_CALLS}"
    [ "${status}" -eq 0 ]
}

@test "validator accepts blank lines and # comments" {
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
# Header comment

[Flatpak Preinstall org.gnome.Calculator]
Branch=stable

# Trailing comment
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"1 preinstall files, 1 app checks, 0 failures."* ]]
}

@test "validator rejects a ';' comment, which flatpak parses as a syntax error" {
    # flatpak's parser is GKeyFile: ';' is not a comment character, and a
    # malformed line makes it discard the whole file while still exiting 0.
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
# Header
;[Flatpak Preinstall org.gnome.Calculator]
;Branch=stable

[Flatpak Preinstall org.gnome.TextEditor]
Branch=stable
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"FAIL: ${FIXTURES}/base.preinstall:2: not a # comment"* ]]
    [[ "${output}" == *"FAIL: ${FIXTURES}/base.preinstall:3: not a # comment"* ]]
    # The well-formed section is still checked and reported.
    [[ "${output}" == *"PASS: ${FIXTURES}/base.preinstall: org.gnome.TextEditor (stable)"* ]]
    [[ "${output}" == *"1 app checks, 2 failures."* ]]
}

@test "validator rejects a group header flatpak would skip" {
    # Groups are matched by prefix and anything else is skipped at g_info level,
    # so a header with no app-id installs nothing and says nothing.
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
[Flatpak Preinstall]
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"FAIL: ${FIXTURES}/base.preinstall:1: not a # comment"* ]]
}

@test "validator resolves a file named after a pinned remote on that remote" {
    cat > "${FIXTURES}/flatpark.preinstall" <<'EOF'
[Flatpak Preinstall org.eurooffice.desktopeditors]
Branch=stable
EOF
    cat > "${FIXTURES}/default.preinstall" <<'EOF'
[Flatpak Preinstall org.gnome.Calculator]
Branch=stable
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 0 ]
    run grep -c '^remote-add --user --if-not-exists flatpark .*fixtures/flatpark.flatpakrepo$' "${CALLS}"
    [ "${output}" = "1" ]
    grep -qx 'remote-info --user flatpark org.eurooffice.desktopeditors//stable' "${CALLS}"
    grep -qx 'remote-info --user flathub org.gnome.Calculator//stable' "${CALLS}"
}

@test "validator names the remote an app is missing from" {
    export MOCK_REMOTE_FAILURES="org.example.Gone"
    cat > "${FIXTURES}/flatpark.preinstall" <<'EOF'
[Flatpak Preinstall org.example.Gone]
Branch=stable
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"org.example.Gone: not on flatpark at branch stable (exit 42)"* ]]
}

@test "validator falls back to flathub for a file named after a remote with no fixture" {
    cat > "${FIXTURES}/nosuchremote.preinstall" <<'EOF'
[Flatpak Preinstall org.gnome.Calculator]
Branch=stable
EOF
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 0 ]
    grep -qx 'remote-info --user flathub org.gnome.Calculator//stable' "${CALLS}"
    run grep -c '^remote-add' "${CALLS}"
    [ "${output}" = "1" ]
}

_with_preinstall_and_brew() {
    cat > "${FIXTURES}/base.preinstall" <<'EOF'
[Flatpak Preinstall org.gnome.Calculator]
Branch=stable
EOF
    BREWS="${WORKDIR}/brew"
    mkdir -p "${BREWS}"
}

@test "validator resolves Brewfile flatpak entries on flathub, unbranched" {
    _with_preinstall_and_brew
    cat > "${BREWS}/gaming.Brewfile" <<'EOF'
# Gaming
brew "tmux"
flatpak "com.valvesoftware.Steam"
  flatpak "com.vysp3r.ProtonPlus" # trailing comment
EOF
    run bash "${SCRIPT}" "${FIXTURES}" "${BREWS}"
    [ "${status}" -eq 0 ]
    grep -qx 'remote-info --user flathub com.valvesoftware.Steam' "${CALLS}"
    grep -qx 'remote-info --user flathub com.vysp3r.ProtonPlus' "${CALLS}"
    # brew lines belong to validate-brewfiles.sh, not here.
    ! grep -q 'tmux' "${CALLS}"
    [[ "${output}" == *"3 app checks, 0 failures."* ]]
}

@test "validator fails a Brewfile flatpak entry that is not on flathub" {
    _with_preinstall_and_brew
    export MOCK_REMOTE_FAILURES="com.example.Missing"
    printf 'flatpak "com.example.Missing"\n' > "${BREWS}/x.Brewfile"
    run bash "${SCRIPT}" "${FIXTURES}" "${BREWS}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"x.Brewfile:1: flatpak com.example.Missing: not on flathub (exit 42)"* ]]
}

@test "validator fails closed on a Brewfile flatpak entry with options" {
    _with_preinstall_and_brew
    printf 'flatpak "com.example.App", remote: "elsewhere"\n' > "${BREWS}/x.Brewfile"
    run bash "${SCRIPT}" "${FIXTURES}" "${BREWS}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *'x.Brewfile:1: expected a literal flatpak "<app-id>" with no options'* ]]
    ! grep -q 'com.example.App' "${CALLS}"
}

@test "validator fails closed on a computed Brewfile flatpak entry" {
    _with_preinstall_and_brew
    printf 'flatpak "com.example.#{name}"\n' > "${BREWS}/x.Brewfile"
    run bash "${SCRIPT}" "${FIXTURES}" "${BREWS}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"expected a literal flatpak"* ]]
}

@test "validator with one directory argument checks no Brewfiles" {
    _with_preinstall_and_brew
    printf 'flatpak "com.example.App"\n' > "${BREWS}/x.Brewfile"
    run bash "${SCRIPT}" "${FIXTURES}"
    [ "${status}" -eq 0 ]
    ! grep -q 'com.example.App' "${CALLS}"
}

@test "validator fails closed when the Brewfile directory does not exist" {
    _with_preinstall_and_brew
    run bash "${SCRIPT}" "${FIXTURES}" "${WORKDIR}/nope"
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"Brewfile directory does not exist"* ]]
}

@test "validator rejects more than two arguments" {
    run bash "${SCRIPT}" a b c
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"Usage:"* ]]
}
