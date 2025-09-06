#!/usr/bin/env bash

# Filesystem configuration script sets up multiple filesystems and partitions:
# - Formats partitions based on Dual-boot preference
# - Creates btrfs subvolumes
# - Mounts btrfs subvolumes
# - Creates and mounts efi partition

# Formats partitions with filesystems
format_partitions() {
    log_info "Formatting partitions..."
    # shellcheck disable=SC2154
    mkfs.fat -F 32 "${disk}1" > /dev/null 2>&1
    # shellcheck disable=SC2154
    if [[ ${no_windows} == 0 ]]; then
		mkfs.ntfs -f "${disk}3" > /dev/null 2>&1
	fi
    # shellcheck disable=SC2154
    mkfs.btrfs -f "${disk}${root_idx}" > /dev/null 2>&1
    # shellcheck disable=SC2034
    root_uuid=$(blkid -s PARTUUID -o value "${disk}${root_idx}")
	log_success "Partitions formatted."
}

# Creates btrfs subvolumes
create_btrfs_subvolumes() {
    log_info "Creating btrfs subvolumes..."
	mount "${disk}${root_idx}" /mnt > /dev/null 2>&1
	btrfs subvolume create /mnt/@ > /dev/null 2>&1
	btrfs subvolume create /mnt/@home > /dev/null 2>&1
	btrfs subvolume create /mnt/@snapshots > /dev/null 2>&1
	btrfs subvolume create /mnt/@cache > /dev/null 2>&1
	btrfs subvolume create /mnt/@log > /dev/null 2>&1
	umount /mnt > /dev/null 2>&1
	log_success "Subvolumes created."
}

# Mounts btrfs subvolumes
mount_btrfs_subvolumes() {
	log_info "Mounting btrfs subvolumes..."
    mount -o compress=zstd:1,subvol=@ "${disk}${root_idx}" /mnt > /dev/null 2>&1
	mkdir -p /mnt/home /mnt/.snapshots /mnt/var/cache /mnt/var/log > /dev/null 2>&1
	mount -o compress=zstd:1,subvol=@home "${disk}${root_idx}" /mnt/home > /dev/null 2>&1
	mount -o compress=zstd:1,subvol=@snapshots "${disk}${root_idx}" /mnt/.snapshots > /dev/null 2>&1
	mount -o compress=zstd:1,subvol=@cache "${disk}${root_idx}" /mnt/var/cache > /dev/null 2>&1
	mount -o compress=zstd:1,subvol=@log "${disk}${root_idx}" /mnt/var/log > /dev/null 2>&1
	log_success "Subvolumes mounted."
}

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