#!/bin/bash
# Install the extensions listed in gnome-extensions.txt system-wide.

set -ouex pipefail

EXT_DIR=/usr/share/gnome-shell/extensions
SCHEMA_DIR=/usr/share/glib-2.0/schemas
EGO=https://extensions.gnome.org
# extensions.gnome.org sometimes drops connections; retry those too.
CURL=(curl -fsSL --retry 5 --retry-all-errors --retry-delay 5)

# Tools this step needs (normally already in Bluefin).
for tool in curl jq unzip; do
    command -v "${tool}" >/dev/null || dnf5 -y install "${tool}"
done

# Major GNOME Shell version of the base image, e.g. "50".
SHELL_VERSION="$(gnome-shell --version | grep -oE '[0-9]+' | head -n1)"

mkdir -p /usr/share/ampersand
: >/usr/share/ampersand/gnome-extensions.txt

grep -vE '^\s*(#|$)' /ctx/gnome-extensions.txt | while read -r uuid; do
    # Ask extensions.gnome.org for the newest release that supports this GNOME.
    info="$("${CURL[@]}" "${EGO}/extension-info/?uuid=${uuid}&shell_version=${SHELL_VERSION}")" || {
        echo "::error::${uuid}: no release for GNOME ${SHELL_VERSION}, or extensions.gnome.org unreachable (see curl error above)"
        exit 1
    }
    version="$(jq -r '.version' <<<"${info}")"
    download="$(jq -r '.download_url' <<<"${info}")"

    "${CURL[@]}" -o /tmp/ext.zip "${EGO}${download}"
    rm -rf "${EXT_DIR:?}/${uuid}"
    unzip -q /tmp/ext.zip -d "${EXT_DIR}/${uuid}"
    rm -f /tmp/ext.zip
    # extensions.gnome.org zips keep odd permissions (metadata.json root-only,
    # everything else world-writable). GNOME runs as the user, so make the
    # files readable by everyone and writable only by root.
    chmod -R u=rwX,go=rX "${EXT_DIR}/${uuid}"

    # Double-check the release really lists this GNOME version.
    jq -e --arg v "${SHELL_VERSION}" '."shell-version" | index($v)' \
        "${EXT_DIR}/${uuid}/metadata.json" >/dev/null || {
        echo "::error::${uuid} v${version} does not list GNOME ${SHELL_VERSION} in metadata.json"
        exit 1
    }

    # Move the settings schema to the system schema folder, so Ampersand's
    # defaults (gschema override) apply to it. A compiled copy inside the
    # extension would take priority and hide those defaults, so drop it.
    if [[ -d "${EXT_DIR}/${uuid}/schemas" ]]; then
        cp "${EXT_DIR}/${uuid}"/schemas/*.gschema.xml "${SCHEMA_DIR}/" 2>/dev/null || true
        rm -f "${EXT_DIR}/${uuid}/schemas/gschemas.compiled"
    fi

    echo "${uuid} ${version}" >>/usr/share/ampersand/gnome-extensions.txt
done

cat /usr/share/ampersand/gnome-extensions.txt

# Every extension must be readable by normal users and writable only by root,
# or GNOME silently skips it.
bad="$(find "${EXT_DIR}" \( ! -perm -o=r -o -perm /go=w \) -print)"
if [[ -n "${bad}" ]]; then
    echo "${bad}"
    echo "::error::files above in ${EXT_DIR} are not world-readable or are group/world-writable"
    exit 1
fi
