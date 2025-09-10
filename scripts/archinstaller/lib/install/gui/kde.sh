#!/usr/bin/env bash

install_de_kde() {
    log_info "Installing KDE Plasma Desktop Environment..."
    arch-chroot pacman -S --noconfirm plasma qt6-multimedia-ffmpeg pipewire-jack noto-fonts
    log_success "KDE Plasma Desktop Environment installed."
}