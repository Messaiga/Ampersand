#!/usr/bin/env bash
# Titanoboa post-rootfs hook: turns the Ampersand image into the live installer.
# Copied from Bluefin (projectbluefin/iso, iso_files/configure_iso_anaconda.sh)
# so the ISO behaves like Bluefin's: web installer, Flatpaks copied from the ISO,
# then a signed switch to our image. Since Ampersand moved to Silverblue +
# Common (2026-10-30) it has no Universal Blue kernel modules, so Bluefin's
# Secure Boot key enrolment (MOK) is removed: Fedora's own signed kernel boots.
# Ampersand changes are marked "Ampersand:". When Bluefin changes theirs, diff
# and copy the change over.
#
# Run by .github/workflows/build-disk.yml, which names the image to install.

set -eoux pipefail

IMAGE_INFO="$(cat /usr/share/ublue-os/image-info.json)"
IMAGE_TAG="$(jq -c -r '."image-tag"' <<<"$IMAGE_INFO")"
IMAGE_REF="$(jq -c -r '."image-ref"' <<<"$IMAGE_INFO")"
IMAGE_REF="${IMAGE_REF##*://}"
# Ampersand: the ISO workflow puts the image it builds from in AMPERSAND_IMAGE_REF
# and AMPERSAND_IMAGE_TAG at the top of this script; those win over image-info.json.
IMAGE_REF="${AMPERSAND_IMAGE_REF:-$IMAGE_REF}"
IMAGE_TAG="${AMPERSAND_IMAGE_TAG:-$IMAGE_TAG}"

# Configure Live Environment

# Setup dock
tee /usr/share/glib-2.0/schemas/zz2-org.gnome.shell.gschema.override <<EOF
[org.gnome.shell]
welcome-dialog-last-shown-version='4294967295'
favorite-apps = ['anaconda.desktop', 'documentation.desktop', 'discourse.desktop', 'org.mozilla.firefox.desktop', 'org.gnome.Nautilus.desktop']
EOF

# Disable suspend/sleep during live environment and initial setup
# This prevents the system from suspending during installation or first-boot user creation
tee /usr/share/glib-2.0/schemas/zz3-bluefin-installer-power.gschema.override <<EOF
[org.gnome.settings-daemon.plugins.power]
sleep-inactive-ac-type='nothing'
sleep-inactive-battery-type='nothing'
sleep-inactive-ac-timeout=0
sleep-inactive-battery-timeout=0

[org.gnome.desktop.session]
idle-delay=uint32 0
EOF

# don't autostart gnome-software session service
rm -f /etc/xdg/autostart/org.gnome.Software.desktop

# disable the gnome-software shell search provider
tee /usr/share/gnome-shell/search-providers/org.gnome.Software-search-provider.ini <<EOF
DefaultDisabled=true
EOF

glib-compile-schemas /usr/share/glib-2.0/schemas

# Ampersand: only units this image has (Bluefin's list assumes Bluefin's units).
for unit in rpm-ostree-countme.service tailscaled.service bootloader-update.service \
    brew-upgrade.timer brew-update.timer brew-setup.service rpm-ostreed-automatic.timer \
    uupd.timer ublue-system-setup.service flatpak-preinstall.service; do
    if systemctl list-unit-files --no-legend "${unit}" | grep -q .; then
        systemctl disable "${unit}"
    fi
done
for unit in podman-auto-update.timer ublue-user-setup.service; do
    if systemctl --global list-unit-files --no-legend "${unit}" 2>/dev/null | grep -q .; then
        systemctl --global disable "${unit}"
    fi
done

# Ampersand: no setup offer, accent watcher or voice typing in the live session.
# Only units the image has: the ISO is built from the published image, which
# can be a release behind this repo (local-ai-firstrun was replaced by setup-offer).
for unit in ampersand-setup-offer.service ampersand-local-ai-firstrun.service ampersand-icon-accent.service; do
    if [[ -e "/usr/lib/systemd/user/${unit}" ]]; then
        systemctl --global disable "${unit}"
    fi
done
rm -f /etc/xdg/autostart/ampersand-speedofsound.desktop

# Configure Anaconda

# Install Anaconda, Webui if >= F42
SPECS=(
    "libblockdev-btrfs"
    "libblockdev-lvm"
    "libblockdev-dm"
    "anaconda-live"
    "firefox"
)

dnf install -y "${SPECS[@]}"

# Anaconda Profile Detection

# Ampersand: its own profile. The image keeps Fedora's ID=fedora and sets
# VARIANT_ID=ampersand (Finpilot's build/00-image-info.sh).
tee /etc/anaconda/profile.d/ampersand.conf <<'EOF'
# Anaconda configuration file for Ampersand (adapted from Bluefin's)

[Profile]
# Define the profile.
profile_id = ampersand
base_profile = fedora-silverblue

[Profile Detection]
# Match os-release values
os_id = fedora
variant_id = ampersand

[Network]
default_on_boot = FIRST_WIRED_WITH_LINK

[Bootloader]
efi_dir = fedora
menu_auto_hide = True

[Storage]
default_scheme = BTRFS
btrfs_compression = zstd:1
default_partitioning =
    /     (min 1 GiB, max 70 GiB)
    /home (min 500 MiB, free 50 GiB)
    /var  (btrfs)

[User Interface]
custom_stylesheet = /usr/share/anaconda/pixmaps/silverblue/fedora-silverblue.css
webui_web_engine = slitherer
hidden_spokes =
    NetworkSpoke
    PasswordSpoke
    UserSpoke
hidden_webui_pages =
    anaconda-screen-accounts

[Localization]
use_geolocation = False
EOF


# Configure
# shellcheck source=/dev/null
. /etc/os-release
echo "Ampersand release $VERSION_ID" >/etc/system-release
sed -i 's/ANACONDA_PRODUCTVERSION=.*/ANACONDA_PRODUCTVERSION=""/' /usr/{,s}bin/liveinst || true
sed -i 's|^Icon=.*|Icon=/usr/share/pixmaps/fedora-logo-icon.png|' /usr/share/applications/liveinst.desktop || true
sed -i 's| Fedora| Ampersand|' /usr/share/anaconda/gnome/fedora-welcome || true
sed -i 's|Activities|in the dock|' /usr/share/anaconda/gnome/fedora-welcome || true

# Get Artwork
git clone --depth=1 https://github.com/projectbluefin/branding.git /tmp/branding
mkdir -p /usr/share/anaconda/pixmaps/silverblue
cp -r /tmp/branding/anaconda/* /usr/share/anaconda/pixmaps/silverblue/
rm -rf /tmp/branding

# Interactive Kickstart
tee -a /usr/share/anaconda/interactive-defaults.ks <<EOF
ostreecontainer --url=$IMAGE_REF:$IMAGE_TAG --transport=containers-storage --no-signature-verification
%include /usr/share/anaconda/post-scripts/install-configure-upgrade.ks
%include /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks
%include /usr/share/anaconda/post-scripts/install-flatpaks.ks
EOF

# Signed Images
tee /usr/share/anaconda/post-scripts/install-configure-upgrade.ks <<EOF
%post --erroronfail
bootc switch --mutate-in-place --enforce-container-sigpolicy --transport registry $IMAGE_REF:$IMAGE_TAG
%end
EOF

# Disable Fedora Flatpak
tee /usr/share/anaconda/post-scripts/disable-fedora-flatpak.ks <<'EOF'
%post --erroronfail
systemctl disable flatpak-add-fedora-repos.service
%end
EOF

# Install Flatpaks
tee /usr/share/anaconda/post-scripts/install-flatpaks.ks <<'EOF'
%post --erroronfail --nochroot
deployment="$(ostree rev-parse --repo=/mnt/sysimage/ostree/repo ostree/0/1/0)"
target="/mnt/sysimage/ostree/deploy/default/deploy/$deployment.0/var/lib/"
mkdir -p "$target"
rsync -aAXUHKP /var/lib/flatpak "$target"
%end
EOF


sed -i -e "s/Fedora/Ampersand/g" -e "s/CentOS/Ampersand/g" /usr/share/anaconda/gnome/org.fedoraproject.welcome-screen.desktop
