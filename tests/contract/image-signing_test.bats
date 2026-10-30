#!/usr/bin/env bats
# Contract: the update transport in image-info.json and the trust policy the
# image actually ships must agree. They are written in different files that
# cannot read each other, and getting them out of step is silent in both
# directions:
#
#   signed transport, no matching policy scope -> verification "succeeds"
#       against Common's `""` catch-all (insecureAcceptAnything) and checks
#       nothing, while image-info.json and the README claim it does.
#   policy scope, unverified transport -> the scope is never consulted, so a
#       signature the operator believes is enforced is not.
#
# Ampersand deviates from Finpilot here (README "Image signing"): CI signs
# every image with the cosign key in SIGNING_SECRET as well as keyless, the
# image trusts that key for ghcr.io/messaiga, and the update transport is
# signed. Finpilot's version of this file asserts the opposite of each test.

REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"
IMAGE_INFO_SRC="${REPO_ROOT}/build/00-image-info.sh"
SIGNING_SRC="${REPO_ROOT}/build/44-ampersand.sh"

@test "image-signing: the update ref uses the signed transport" {
    run grep -cE '^IMAGE_REF="ostree-image-signed:docker://' "${IMAGE_INFO_SRC}"
    [ "$status" -eq 0 ]
    [ "$output" -eq 1 ]
}

@test "image-signing: the update ref keeps the docker:// spelling" {
    # `just build-iso` recovers the published reference from image-info.json
    # with `sed 's|.*docker://||'`.
    run grep -F "sed 's|.*docker://||'" "${REPO_ROOT}/Justfile"
    [ "$status" -eq 0 ]
}

@test "image-signing: a build phase merges a sigstoreSigned scope for ghcr.io/messaiga" {
    run grep -F '.transports.docker["ghcr.io/messaiga"]' "${SIGNING_SRC}"
    [ "$status" -eq 0 ]
    run grep -F '"type": "sigstoreSigned"' "${SIGNING_SRC}"
    [ "$status" -eq 0 ]
}

@test "image-signing: the scope names the key file the build installs" {
    key_path="$(sed -n 's/.*"keyPath": "\([^"]*\)".*/\1/p' "${SIGNING_SRC}")"
    [ -n "${key_path}" ]
    run grep -F "install -Dm0644 /ctx/cosign.pub ${key_path}" "${SIGNING_SRC}"
    [ "$status" -eq 0 ]
}

@test "image-signing: the public key is in the repository and in the build context" {
    [ -s "${REPO_ROOT}/cosign.pub" ]
    run grep -F 'BEGIN PUBLIC KEY' "${REPO_ROOT}/cosign.pub"
    [ "$status" -eq 0 ]
    run grep -xF 'COPY cosign.pub /cosign.pub' "${REPO_ROOT}/Containerfile"
    [ "$status" -eq 0 ]
}

@test "image-signing: a registries.d entry makes clients fetch the signatures" {
    file="${REPO_ROOT}/custom/files/etc/containers/registries.d/messaiga.yaml"
    [ -f "${file}" ]
    run grep -E '^  ghcr.io/messaiga:$' "${file}"
    [ "$status" -eq 0 ]
    run grep -E '^    use-sigstore-attachments: true$' "${file}"
    [ "$status" -eq 0 ]
}

@test "image-signing: the image ships no whole trust policy of its own" {
    # policy.json has no drop-in directory, so shipping one through
    # custom/files would replace Common's wholesale and freeze every scope.
    [ ! -e "${REPO_ROOT}/custom/files/etc/containers/policy.json" ]
}

@test "image-signing: CI signs the pushed digest with the repository key" {
    workflow="${REPO_ROOT}/.github/workflows/build-image.yml"
    run grep -F 'COSIGN_PRIVATE_KEY: ${{ secrets.SIGNING_SECRET }}' "${workflow}"
    [ "$status" -eq 0 ]
    run grep -F -- '--key env://COSIGN_PRIVATE_KEY' "${workflow}"
    [ "$status" -eq 0 ]
}

@test "image-signing: the README says where the signature is checked" {
    run grep -F 'verified on the device' "${REPO_ROOT}/README.md"
    [ "$status" -eq 0 ]
}
