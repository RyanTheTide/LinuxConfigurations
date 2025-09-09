#!/usr/bin/env bash

install_de_kde() {
    log_info "Installing KDE Plasma Desktop Environment..."
    arch-chroot pacman -S --noconfirm plasma
    log_success "KDE Plasma Desktop Environment installed."
}