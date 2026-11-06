# vim: set ft=make :
####################
### custom-apps.just
####################
## Homebrew shortcuts and Flatpak app groups.
##
## Every Brewfile in custom/brew/ is copied to /usr/share/ublue-os/homebrew/ at
## build time. Add a recipe here for each one, so users install it with `ujust`
## instead of remembering the path.
##
## An app group is a Brewfile of `flatpak "<app-id>"` lines. Its recipe hands
## the Brewfile to /usr/libexec/ampersand/flatpak-group.sh, which installs the
## whole group, or offers to complete or remove it when some or all of it is
## already installed. spec/flatpaks.md lists every group.
##
## See custom/brew/README.md.

# Install default applications via Homebrew
[group('Apps')]
install-default-apps:
    #!/usr/bin/env bash
    echo "Installing default applications via Homebrew..."
    brew bundle --file /usr/share/ublue-os/homebrew/default.Brewfile

# Install development tools via Homebrew
[group('Apps')]
install-dev-tools:
    #!/usr/bin/env bash
    echo "Installing development tools via Homebrew..."
    brew bundle --file /usr/share/ublue-os/homebrew/development.Brewfile

# Install, complete or remove the AI assistant apps (Newelle)
[group('Apps')]
install-ai-assistant:
    #!/usr/bin/env bash
    set -euo pipefail
    exec /usr/bin/bash /usr/libexec/ampersand/flatpak-group.sh "AI assistant" /usr/share/ublue-os/homebrew/ai-assistant.Brewfile

# Install, complete or remove the developer desktop apps
[group('Apps')]
install-dev-apps:
    #!/usr/bin/env bash
    set -euo pipefail
    exec /usr/bin/bash /usr/libexec/ampersand/flatpak-group.sh "developer" /usr/share/ublue-os/homebrew/dev-apps.Brewfile

# Install, complete or remove Bluefin's developer experience apps, unchanged from upstream
[group('Apps')]
install-dx-apps:
    #!/usr/bin/env bash
    set -euo pipefail
    exec /usr/bin/bash /usr/libexec/ampersand/flatpak-group.sh "Bluefin developer experience" /usr/share/ublue-os/homebrew/system-dx-flatpaks.Brewfile

# Install, complete or remove the media viewing and conversion apps
[group('Apps')]
install-media-apps:
    #!/usr/bin/env bash
    set -euo pipefail
    exec /usr/bin/bash /usr/libexec/ampersand/flatpak-group.sh "media" /usr/share/ublue-os/homebrew/media.Brewfile

# Install, complete or remove the audio, video and music production apps
[group('Apps')]
install-media-production:
    #!/usr/bin/env bash
    set -euo pipefail
    exec /usr/bin/bash /usr/libexec/ampersand/flatpak-group.sh "media production" /usr/share/ublue-os/homebrew/media-production.Brewfile

# Install, complete or remove the gaming apps
[group('Apps')]
install-gaming:
    #!/usr/bin/env bash
    set -euo pipefail
    exec /usr/bin/bash /usr/libexec/ampersand/flatpak-group.sh "gaming" /usr/share/ublue-os/homebrew/gaming.Brewfile
