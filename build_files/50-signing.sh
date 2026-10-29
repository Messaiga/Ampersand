#!/bin/bash
# Trust Ampersand's signing key, so updates (bootc upgrade/switch with
# --enforce-container-sigpolicy) only accept images signed by this repo's CI.
# Same pattern Bluefin uses for ghcr.io/ublue-os.

set -ouex pipefail

install -Dm0644 /ctx/cosign.pub /usr/lib/pki/containers/messaiga.pub

policy=/etc/containers/policy.json
jq '.transports.docker["ghcr.io/messaiga"] = [{
        "type": "sigstoreSigned",
        "keyPath": "/usr/lib/pki/containers/messaiga.pub",
        "signedIdentity": {"type": "matchRepository"}
    }]' "${policy}" >/tmp/policy.json
install -m0644 /tmp/policy.json "${policy}"
jq -e '.transports.docker["ghcr.io/messaiga"]' "${policy}"
