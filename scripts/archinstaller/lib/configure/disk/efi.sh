#!/usr/bin/env bash
#shellcheck disable=SC2154

# Creates efi partition
create_efi_volume() {
	log_info "Creating EFI volume..."
    mkdir -p /mnt/efi
	log_success "EFI volume created."
}

# Mounts efi partition
mount_efi_volume() {
	log_info "Mounting EFI volume..."
    mount "${disk}1" /mnt/efi > /dev/null 2>&1
	log_success "EFI volume mounted."
}