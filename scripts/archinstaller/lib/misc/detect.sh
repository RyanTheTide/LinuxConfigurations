#!/usr/bin/env bash

# Detect cpu manufacturer (Intel/AMD)
detect_cpu_manufacturer() {
    local __var
    __var=$(lscpu | awk -F: '/Vendor ID/ {gsub(/^[ \t]+/, "", $2); print $2}')
    if [[ $__var == "GenuineIntel" ]]; then
        cpu_manufacturer="intel"
    elif [[ $__var == "AuthenticAMD" ]]; then
        # shellcheck disable=SC2034
        cpu_manufacturer="amd"
    else
        # shellcheck disable=SC2034
        cpu_manufacturer="unknown"
    fi
}
# Detect if installing in a virtualized environment
detect_virtualization() {
    local __var
    __var=$(systemd-detect-virt 2>/dev/null || echo "none")
    if [[ "$__var" != "none" ]]; then
        is_virtualization=1
        hypervisor_type="$__var"
    else
        # shellcheck disable=SC2034
        is_virtualization=0
        # shellcheck disable=SC2034
        hypervisor_type="none"
    fi
}
# Detect if Secure Boot is in Setup Mode (enabled)
detect_secureboot() {
    local __var1 __var2
    if ! command -v sbctl >/dev/null 2>&1; then
        pacman -Sy --noconfirm sbctl >/dev/null 2>&1
    fi
    __var1=$(sbctl status 2>/dev/null | grep -i '^Setup Mode:.*Enabled' || true)
    if [[ -n "$__var1" ]]; then
        __var2=$(awk -F': *' '{print tolower($0)}' <<<"$__var1" | awk '{print $NF}')
        if [[ "$__var2" == "enabled" ]]; then
            is_secureboot=1
        else
            is_secureboot=0
        fi
        return 0
    fi
    # shellcheck disable=SC2034
    is_secureboot=0
}
# Detect if UEFI is enabled
detect_uefi() {
    if [[ ! -d /sys/firmware/efi/efivars ]]; then
        log_fatal "UEFI not detected. This installer currently only supports UEFI systems."
    fi
}