#!/usr/bin/env bash

install_gpu_amd() {
    log_info "Installing AMD GPU drivers..."
    arch-chroot /mnt pacman -S --noconfirm mesa vulkan-radeon > /dev/null 2>&1
    log_success "AMD GPU drivers installed."
}

install_gpu_nvidia() {
    log_info "Installing NVIDIA GPU drivers..."
    arch-chroot /mnt pacman -S --noconfirm nvidia-open nvidia-utils > /dev/null 2>&1
    log_success "NVIDIA GPU drivers installed."
}

install_gpu_intel() {
    log_info "Installing Intel GPU drivers..."
    arch-chroot /mnt pacman -S --noconfirm mesa vulkan-intel > /dev/null 2>&1
    log_success "Intel GPU drivers installed."
}

install_gpu() {
    local -A need=()
    local v
    # Collect from dGPU
    for v in "${mgpu_manufacturer:-}" "${sgpu_manufacturer:-}" "${tgpu_manufacturer:-}"; do
        case "$v" in
            nvidia|amd|intel) need["$v"]=1 ;;
        esac
    done
    # Collect from iGPU
    if [[ ${is_igpu:-0} -eq 1 ]]; then
        case "${igpu_manufacturer:-}" in
            nvidia|amd|intel) need["${igpu_manufacturer}"]=1 ;;
        esac
    fi
    # If nothing matched
    if [[ ${#need[@]} -eq 0 ]]; then
        log_warn "No supported GPU vendors detected; skipping GPU driver install."
        return 0
    fi
    # Install order
    for v in nvidia amd intel; do
        [[ -n "${need[$v]:-}" ]] || continue
        "install_gpu_${v}"
    done
}




