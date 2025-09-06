#!/usr/bin/env bash

# Mirror configuration script sets up reflector and configures mirrors based on country variable.

set_mirrors() {
    arch-chroot /mnt pacman -S --noconfirm reflector > /dev/null 2>&1
    log_info "Configuring Mirrors..."
    # shellcheck disable=SC2154
    arch-chroot /mnt reflector --country "${country}" --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist > /dev/null 2>&1
    log_success "Mirrors configured."
}
