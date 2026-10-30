#!/usr/bin/env bash
# Compile Ampersand's GNOME defaults into the image.

set -ouex pipefail

# Rebuild the settings schema cache (picks up zz1-ampersand.gschema.override and
# the extension schemas copied in 40-gnome-extensions.sh). A typo in a key name
# only prints a warning, so treat any warning about our file as a build error.
rm -f /usr/share/glib-2.0/schemas/gschemas.compiled
glib-compile-schemas /usr/share/glib-2.0/schemas 2>&1 | tee /tmp/schemas.log
if grep -q 'zz1-ampersand' /tmp/schemas.log; then
    echo "::error::zz1-ampersand.gschema.override has an invalid key or value (see above)"
    exit 1
fi

# The default wallpaper comes from GNOME's backgrounds package; fail if it moves.
for wallpaper in fold-l fold-d; do
    test -f "/usr/share/backgrounds/gnome/${wallpaper}.jxl" || {
        echo "::error::/usr/share/backgrounds/gnome/${wallpaper}.jxl is missing (default wallpaper)"
        exit 1
    }
done

# Our dconf keyfiles live in /etc/dconf/db/distro.d, which GNOME only reads if
# the user profile lists that database. Bluefin's image shipped such a profile;
# Common doesn't. Keep the base's profile if it already has the line, otherwise
# write the order Bluefin used (user settings > local > site > distro).
profile=/etc/dconf/profile/user
if ! grep -qx 'system-db:distro' "${profile}" 2>/dev/null; then
    echo "${profile} has no system-db:distro; writing one"
    install -d /etc/dconf/profile
    printf '%s\n' user-db:user system-db:local system-db:site system-db:distro >"${profile}"
fi
cat "${profile}"

# Rebuild the dconf system database (custom keyboard shortcuts, extension settings).
dconf update
test -f /etc/dconf/db/distro || {
    echo "::error::dconf update did not build /etc/dconf/db/distro"
    exit 1
}

# User services for every user: folder icons follow the accent colour, and the
# one-time offer to run ujust setup-desktop at first login.
systemctl --global enable ampersand-icon-accent.service ampersand-setup-offer.service
