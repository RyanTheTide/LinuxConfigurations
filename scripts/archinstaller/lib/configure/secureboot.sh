#!/usr/bin/env bash
# shellcheck disable=SC2154

# Secure Boot configuration script sets up Secure Boot using sbctl.
# Please ensure that secure boot is set to "Setup Mode" in your UEFI firmware settings before proceeding.

set_secureboot() {
    arch-chroot /mnt pacman -S --noconfirm sbctl > /dev/null 2>&1
    log_info "Configuring Secure Boot..."
    arch-chroot /mnt sbctl create-keys > /dev/null 2>&1
    arch-chroot /mnt sbctl enroll-keys --microsoft > /dev/null 2>&1
    arch-chroot /mnt sbctl sign -s /boot/vmlinuz-linux > /dev/null 2>&1
    if [[ ${is_refind} == 1 ]]; then
        arch-chroot /mnt sbctl sign -s /efi/EFI/refind/refind_x64.efi > /dev/null 2>&1
        arch-chroot /mnt sbctl sign -s /efi/EFI/refind/drivers_x64/btrfs_x64.efi > /dev/null 2>&1
    fi
    log_success "Secure Boot configured."
}
