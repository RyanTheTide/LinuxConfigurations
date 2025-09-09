#!/usr/bin/env bash

install_de_gnome() {
    log_info "Installing GNOME Desktop Environment..."
    arch-chroot pacman -S --noconfirm gnome
    log_success "GNOME Desktop Environment installed."
}