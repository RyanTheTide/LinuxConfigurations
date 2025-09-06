#!/usr/bin/env bash

# Disk input script to select disk and determine if it's an SSD.

input_disk() {
    local __var
    clear
    printf '%.0s-' {1..54}; echo
    lsblk -dn -o NAME,SIZE,MODEL | grep -v '^loop' | awk '{print "/dev/" $1, "-", $2, "-", substr($0, index($0,$3))}'
    printf '%.0s-' {1..54}; echo
    ask __var "Enter the disk to use (e.g., /dev/nvme0n1)"
    [[ -b "$__var" ]] || { log_error "Invalid disk selected."; input_disk; }
    if [[ "$__var" =~ nvme ]]; then
        # shellcheck disable=SC2034
        disk="${__var}p"
        is_ssd=1
    else
        # shellcheck disable=SC2034
        disk="$__var"
        if confirm "Is this disk an SSD?" ; then
            is_ssd=1
        else
            # shellcheck disable=SC2034
            is_ssd=0
        fi
    fi
}