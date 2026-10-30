#!/bin/bash
# Compile Ampersand's GNOME defaults into the image.

set -ouex pipefail

# Rebuild the settings schema cache (picks up zz1-ampersand.gschema.override and
# the extension schemas copied in 10-gnome-extensions.sh). A typo in a key name
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

# Rebuild the dconf system database (custom keyboard shortcuts, extension settings).
dconf update

# User services for every user: folder icons follow the accent colour, and the
# one-time offer to run ujust setup-desktop at first login.
systemctl --global enable ampersand-icon-accent.service ampersand-setup-offer.service
