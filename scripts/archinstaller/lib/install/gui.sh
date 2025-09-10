#!/usr/bin/env bash
# shellcheck disable=SC2034 disable=SC2154

install_de_gnome() {
    log_info "Installing GNOME Desktop Environment..."
    arch-chroot /mnt pacman -S --noconfirm gnome pipewire-jack > /dev/null 2>&1
    log_success "GNOME Desktop Environment installed."
    is_gui_gnome=1
}

install_de_kde() {
    log_info "Installing KDE Plasma Desktop Environment..."
    arch-chroot /mnt pacman -S --noconfirm plasma qt6-multimedia-ffmpeg pipewire-jack noto-fonts > /dev/null 2>&1
    log_success "KDE Plasma Desktop Environment installed."
    is_gui_kde=1
}

install_gui() {
    if [[ ${set_gui} == "gnome" ]]; then
        install_de_gnome
    elif [[ ${set_gui} == "kde" ]]; then
        install_de_kde
    fi
}