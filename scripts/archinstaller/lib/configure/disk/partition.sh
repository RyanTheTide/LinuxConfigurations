#!/usr/bin/env bash
# shellcheck disable=SC2154

# Partition configuration script sets up disk partitions:
# - Creates partition layout based on disk size and Dual-boot preference
# - Creates partitions

# Creates partitions layout
create_partitions_layout() {
    local disksize disksize_mib __var
	__var="${disk%p}"
    disksize=$(lsblk -bno SIZE "${__var}" | head -n1)
    disksize_mib=$((disksize / 1024 / 1024))
	efi_end=2049
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
        win_end=$((remain_start + half_size))
        root_idx=4
    fi
}

# Creates partitions
create_partitions() {
	__var="${disk%p}"
    log_info "Creating partitions..."
	parted -s "${__var}" mklabel gpt
	parted -s "${__var}" mkpart primary fat32 1MiB "${efi_end}"MiB
	parted -s "${__var}" set 1 esp on
	parted -s "${__var}" name 1 "EFI"
	if [[ ${no_windows} == 1 ]]; then
		parted -s "${__var}" mkpart primary btrfs "${efi_end}"MiB 100%
		parted -s "${__var}" name 2 "Arch"
	else
		parted -s "${__var}" mkpart primary "${efi_end}"MiB "${msr_end}"MiB
		parted -s "${__var}" set 2 msftres on
		parted -s "${__var}" name 2 "MSR"
		parted -s "${__var}" mkpart primary ntfs "${msr_end}"MiB "${win_end}"MiB
		parted -s "${__var}" set 3 msftdata on
		parted -s "${__var}" name 3 "Windows"
		parted -s "${__var}" mkpart primary btrfs "${win_end}"MiB 100%
		parted -s "${__var}" name 4 "Arch"
	fi
    partprobe "$__var"
    udevadm settle
    sleep 2
    [[ -b "${disk}1" && -b "${disk}${root_idx}" ]] || log_fatal "Partitions not found!"
    log_success "Partitions created."
}
