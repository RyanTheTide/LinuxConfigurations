#!/usr/bin/env bash
# shellcheck disable=SC2154

# Dotfiles configuration script sets up various RTTDev dotfiles.
# Refer to https://github.com/RyanTheTide/LinuxConfigurations for more information.

configure_dotfiles() {
    log_info "Configuring dotfiles..."
    arch-chroot /mnt su - "${newusername}" -s /bin/bash <<'EOL'
set -euo pipefail
cd "/var/tmp" > /dev/null 2>&1
git clone https://github.com/RyanTheTide/LinuxConfigurations.git > /dev/null 2>&1
cd LinuxConfigurations > /dev/null 2>&1
cp -r dotfiles/. "$HOME" > /dev/null 2>&1
history -c > /dev/null 2>&1
EOL
    log_success "Dotfiles configured."
}
