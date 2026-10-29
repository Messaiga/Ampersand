#!/usr/bin/env bash
# Titanoboa post-rootfs hook: turns the Ampersand image into the live installer.
# Copied from Bluefin (projectbluefin/iso, iso_files/configure_iso_anaconda.sh)
# so the ISO behaves like Bluefin's: web installer, Flatpaks copied from the ISO,
# Secure Boot key enrolment, then a signed switch to our image.
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
sbkey='https://github.com/ublue-os/akmods/raw/main/certs/public_key.der'

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

systemctl disable rpm-ostree-countme.service
systemctl disable tailscaled.service
systemctl disable bootloader-update.service
systemctl disable brew-upgrade.timer
systemctl disable brew-update.timer
systemctl disable brew-setup.service
systemctl disable rpm-ostreed-automatic.timer
systemctl disable uupd.timer
systemctl disable ublue-system-setup.service
systemctl disable flatpak-preinstall.service
systemctl --global disable podman-auto-update.timer
systemctl --global disable ublue-user-setup.service

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

# Bluefin
tee /etc/anaconda/profile.d/bluefin.conf <<'EOF'
# Anaconda configuration file for Bluefin

[Profile]
# Define the profile.
profile_id = bluefin

[Profile Detection]
# Match os-release values
os_id = bluefin

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

if [[ "${IMAGE_TAG}" =~ lts ]]; then
    sed -i 's/^ID=.*/ID=bluefin/' /usr/lib/os-release
    echo "VARIANT_ID=bluefin" >>/usr/lib/os-release
fi

# Configure
. /etc/os-release
echo "Bluefin release $VERSION_ID ($VERSION_CODENAME)" >/etc/system-release
sed -i 's/ANACONDA_PRODUCTVERSION=.*/ANACONDA_PRODUCTVERSION=""/' /usr/{,s}bin/liveinst || true
sed -i 's|^Icon=.*|Icon=/usr/share/pixmaps/fedora-logo-icon.png|' /usr/share/applications/liveinst.desktop || true
sed -i 's| Fedora| Bluefin|' /usr/share/anaconda/gnome/fedora-welcome || true
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
%include /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks
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

# Fetch the Secureboot Public Key
curl --retry 15 -Lo /etc/sb_pubkey.der "$sbkey"

# Enroll Secureboot Key
tee /usr/share/anaconda/post-scripts/secureboot-enroll-key.ks <<'EOF'
%post --erroronfail --nochroot
set -oue pipefail

readonly ENROLLMENT_PASSWORD="universalblue"
readonly SECUREBOOT_KEY="/etc/sb_pubkey.der"

if [[ ! -d "/sys/firmware/efi" ]]; then
    echo "EFI mode not detected. Skipping key enrollment."
    exit 0
fi

if [[ ! -f "$SECUREBOOT_KEY" ]]; then
    echo "Secure boot key not provided: $SECUREBOOT_KEY"
    exit 0
fi

SYS_ID="$(cat /sys/devices/virtual/dmi/id/product_name)"
if [[ ":Jupiter:Galileo:" =~ ":$SYS_ID:" ]]; then
    echo "Steam Deck hardware detected. Skipping key enrollment."
    exit 0
fi

mokutil --timeout -1 || :
echo -e "$ENROLLMENT_PASSWORD\n$ENROLLMENT_PASSWORD" | mokutil --import "$SECUREBOOT_KEY" || :
%end
EOF

sed -i -e "s/Fedora/Bluefin/g" -e "s/CentOS/Bluefin/g" /usr/share/anaconda/gnome/org.fedoraproject.welcome-screen.desktop
