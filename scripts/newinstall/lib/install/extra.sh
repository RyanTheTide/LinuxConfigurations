#!/usr/bin/env bash

# Extra install script installs additional useful packages:
# - base-devel : development tools
# - git, unzip, wget : general tools & utilities
# - btrfs-progs : Btrfs filesystem utilities
# - networkmanager : network management service
# - nano, vim : text editors
# - sudo : privilege escalation
# - zsh and various plugins : Zsh shell and enhancements
# - fastfetch : system information tool

install_extra() {
    log_info "Installing extra packages (this may take a while)..."
    arch-chroot /mnt pacman -Sy --noconfirm \
		base-devel \
        git unzip wget \
		btrfs-progs \
		networkmanager \
		nano vim \
		sudo \
		zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting \
		fastfetch > /dev/null 2>&1
    log_success "Extra packages installed."
}