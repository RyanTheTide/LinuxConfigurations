#!/usr/bin/env bash
#shellcheck disable=SC2154

# Base install script installs the base system with optional CPU microcode.

install_base() {
    if [[ ${is_microcode} -eq 1 ]]; then
        if [[ $cpu_manufacturer == "intel" || $cpu_manufacturer == "amd" ]]; then
            log_info "Installing base system with microcode (this may take a while)..."
            pacstrap -K /mnt base linux linux-firmware "${cpu_manufacturer}"-ucode > /dev/null 2>&1
        else
            log_warn "CPU manufacturer not recognized, skipping microcode installation."
            log_info "Installing base system (this may take a while)..."
            pacstrap -K /mnt base linux linux-firmware > /dev/null 2>&1
        fi
    else
        log_info "Installing base system (this may take a while)..."
        pacstrap -K /mnt base linux linux-firmware > /dev/null 2>&1
    fi
    log_success "Base system installed."
}