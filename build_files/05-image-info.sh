#!/bin/bash
# Point Bluefin's image-info.json at Ampersand, so tools that read it (the
# installer, ujust, fastfetch) name and pull our image instead of Bluefin's.
# Only this file changes: os-release, the OS name and the hostname stay Bluefin's.
set -euo pipefail

INFO=/usr/share/ublue-os/image-info.json
VENDOR=messaiga

jq --arg name "${IMAGE_NAME}" \
   --arg vendor "${VENDOR}" \
   --arg ref "ostree-image-signed:docker://ghcr.io/${VENDOR}/${IMAGE_NAME}" \
   '."image-name" = $name
    | ."image-vendor" = $vendor
    | ."image-ref" = $ref
    | ."image-tag" = "stable"' \
   "${INFO}" > /tmp/image-info.json
install -m 0644 /tmp/image-info.json "${INFO}"
cat "${INFO}"
