#!/usr/bin/env bash

install_de_gnome() {
    log_info "Installing GNOME Desktop Environment..."
    arch-chroot pacman -S --noconfirm gnome pipewire-jack
    log_success "GNOME Desktop Environment installed."
    is_gui_gnome=1
}