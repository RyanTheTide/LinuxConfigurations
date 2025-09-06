#!/usr/bin/env bash

# Services configuration script sets up various systemd services:
# - fstrim.timer : for SSDs (set by is_ssd variable)
# - NetworkManager : network management
# - reflector.timer : to update mirrors (set by is_mirrors variable)

configure_services() {
	log_info "Configuring services..."
    # shellcheck disable=SC2154
    if [[ "${is_ssd}" == 1 ]] ; then
        arch-chroot /mnt systemctl enable fstrim.timer > /dev/null 2>&1
    fi
	arch-chroot /mnt systemctl enable NetworkManager > /dev/null 2>&1
    # shellcheck disable=SC2154
    if [[ "$is_mirrors" == 1 ]] ; then
        arch-chroot /mnt systemctl enable reflector.timer > /dev/null 2>&1
    fi
	log_success "Services configured."
}
