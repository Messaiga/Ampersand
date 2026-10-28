#!/bin/bash
# Icon themes: Hatter (app icons + accent-coloured folders), with MoreWaita and
# Adwaita behind it for any icon Hatter doesn't have.
#
# Lookup order for an icon:  Hatter-<Accent> (folders) -> Hatter -> MoreWaita -> Adwaita
# The accent folder set is switched by ampersand-icon-accent (a user service).

set -ouex pipefail
shopt -s extglob # for the !(...) pattern below; must be on before bash reads it

# Pinned releases. Renovate opens a PR when a new tag appears.
# renovate: datasource=github-tags depName=Mibea/Hatter
HATTER_TAG=V4.0
# renovate: datasource=github-tags depName=somepaulo/MoreWaita
MOREWAITA_TAG=v50.1

ICONS=/usr/share/icons
SRC=/tmp/icons
mkdir -p "${SRC}"

# MoreWaita: copy the theme as its install.sh does (without the dev files).
git clone --depth 1 --branch "${MOREWAITA_TAG}" https://github.com/somepaulo/MoreWaita "${SRC}/morewaita"
mkdir -p "${ICONS}/MoreWaita"
(
    cd "${SRC}/morewaita"
    cp -a !(*.build|*.sh|*.py|*.md|_dev|_extras) "${ICONS}/MoreWaita/"
)
find "${ICONS}/MoreWaita" -name '*.build' -type f -delete

# Hatter: its build script generates one folder-colour theme per GNOME accent.
git clone --depth 1 --branch "${HATTER_TAG}" https://github.com/Mibea/Hatter "${SRC}/hatter"
bash "${SRC}/hatter/Build-Hatter.sh" </dev/null
cp -a "${SRC}/hatter/Build/Hatter" "${ICONS}/"
for accent in Blue Teal Green Yellow Orange Red Pink Purple Slate; do
    cp -a "${SRC}/hatter/Build/Hatter-${accent}" "${ICONS}/"
done

# Make Hatter fall back to MoreWaita before Adwaita.
sed -i 's/^Inherits=.*/Inherits=MoreWaita,Adwaita,AdwaitaLegacy,hicolor/' "${ICONS}/Hatter/index.theme"

for theme in MoreWaita Hatter "${ICONS}"/Hatter-*; do
    gtk-update-icon-cache -f "${ICONS}/${theme##*/}"
done

rm -rf "${SRC}"
