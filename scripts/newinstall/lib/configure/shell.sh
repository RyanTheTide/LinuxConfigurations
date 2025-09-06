#!/usr/bin/env bash

# Shell configuration script sets up various shell enchancements:
# - ohmyzsh : framework for managing zsh configuration
# - ohmyposh : prompt theme engine for any shell

configure_shell() {
    log_info "Configuring shell..."
    # shellcheck disable=SC2154
    arch-chroot /mnt su - "${newusername}" -s /bin/bash <<'EOL'
set -euo pipefail
touch "$HOME/.zshrc" > /dev/null 2>&1
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash -s -- --unattended > /dev/null 2>&1
curl -s https://ohmyposh.dev/install.sh | bash -s > /dev/null 2>&1
"$HOME/.local/bin/oh-my-posh" font install meslo > /dev/null 2>&1
mv "$HOME/.zshrc" "$HOME/.zshrc.bak" > /dev/null 2>&1
EOL
}