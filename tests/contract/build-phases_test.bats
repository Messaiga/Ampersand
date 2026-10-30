#!/usr/bin/env bats
# Contract: the Containerfile runs each build phase by path (`RUN ... /ctx/build/NN-*.sh`),
# so the script must be committed executable. A 100644 script fails the image
# build with "Permission denied" (exit 126), which no other check catches before
# the build on main.

REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"

@test "build phases: every script the Containerfile runs is committed executable" {
    mapfile -t scripts < <(sed -n 's|.*/ctx/\(build/[^ ]*\.sh\).*|\1|p' "${REPO_ROOT}/Containerfile" | sort -u)
    [ "${#scripts[@]}" -gt 0 ]
    failed=0
    for script in "${scripts[@]}"; do
        mode="$(git -C "${REPO_ROOT}" ls-files -s -- "${script}" | awk '{print $1}')"
        if [[ "${mode}" != 100755 ]]; then
            printf 'FAIL: %s is committed as %s, not 100755 (git update-index --chmod=+x)\n' "${script}" "${mode:-untracked}" >&2
            failed=1
        fi
    done
    [ "${failed}" -eq 0 ]
}
