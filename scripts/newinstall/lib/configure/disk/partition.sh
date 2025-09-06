#!/usr/bin/env bash

# Partition configuration script sets up disk partitions:
# - Creates partition layout based on disk size and Dual-boot preference
# - Creates partitions

# Creates partitions layout
create_partitions_layout() {
    local disksize disksize_mib __var
	__var="${disk%p}"
    # shellcheck disable=SC2154
    disksize=$(lsblk -bno SIZE "${__var}" | head -n1)
    disksize_mib=$((disksize / 1024 / 1024))
	efi_end=2049
    # shellcheck disable=SC2154
    if (( no_windows == 1 )); then
        msr_end=${efi_end}
        remain_start=${efi_end}
        remain_size=$((disksize_mib - remain_start))
        half_size=0
        win_end=${remain_start}
        root_idx=2
    else
        msr_end=$((efi_end + 16))
        remain_start=${msr_end}
        remain_size=$((disksize_mib - remain_start))
        half_size=$((remain_size / 2))
        # shellcheck disable=SC2034
        win_end=$((remain_start + half_size))
        # shellcheck disable=SC2034
        root_idx=4
    fi
}

# Creates partitions
create_partitions() {
    # shellcheck disable=SC2154
    log_info "Creating partitions on $disk..."
	parted -s "${disk}" mklabel gpt
	parted -s "${disk}" mkpart primary fat32 1MiB "${efi_end}"MiB
	parted -s "${disk}" set 1 esp on
	parted -s "${disk}" name 1 "EFI"
	if [[ ${no_windows} == 1 ]]; then
		parted -s "${disk}" mkpart primary btrfs "${efi_end}"MiB 100%
		parted -s "${disk}" name 2 "Arch"
	else
		parted -s "${disk}" mkpart primary "${efi_end}"MiB "${msr_end}"MiB
		parted -s "${disk}" set 2 msftres on
		parted -s "${disk}" name 2 "MSR"
		parted -s "${disk}" mkpart primary ntfs "${msr_end}"MiB "${win_end}"MiB
		parted -s "${disk}" set 3 msftdata on
		parted -s "${disk}" name 3 "Windows"
		parted -s "${disk}" mkpart primary btrfs "${win_end}"MiB 100%
		parted -s "${disk}" name 4 "Arch"
	fi
    partprobe "$disk"
    udevadm settle
    sleep 2
    # shellcheck disable=SC2154
    [[ -b "${disk}1" && -b "${disk}${root_idx}" ]] || log_fatal "Partitions not found!"
    log_success "Partitions created."
}
