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
# Detect gpu manufacturer (NVIDIA/AMD/Intel)
detect_gpu_manufacturers() {
    local gpu_lines igpu_lines vendor
    local __var1 __var2 __var3
    gpu_lines=$(lspci -nn | grep "VGA compatible controller")
    gpu_count=$(echo "$gpu_lines" | wc -l)
    if (( gpu_count == 0 )); then
        is_gpu=0
        is_igpu=0
        return 0
    fi
    is_gpu=1
    # Map vendor names for grep
    map_vendor() {
        case "$1" in
            *Intel*)   echo "intel" ;;
            *NVIDIA*)  echo "nvidia" ;;
            *Advanced*|*AMD*|*ATI*) echo "amd" ;;
            *)         echo "unknown" ;;
        esac
    }
    # Detect iGPU
    igpu_lines=$(echo "$gpu_lines" | grep -E "UHD|APU|iGPU|Integrated" || true)
    if [[ -n "$igpu_lines" ]]; then
        igpu_manufacturer=$(map_vendor "$igpu_lines")
        is_igpu=1
        # Remove from main list
        gpu_lines=$(echo "$gpu_lines" | grep -Ev "UHD|APU|iGPU|Integrated")
    else
        igpu_manufacturer=""
        is_igpu=0
    fi
    # Process vendor names & export temporary variables
    local i=1
    while read -r line; do
        [[ -z "$line" ]] && continue
        vendor=$(map_vendor "$line")
        case $i in
            1) __var1=$vendor ;;
            2) __var2=$vendor ;;
            3) __var3=$vendor ;;
        esac
        ((i++))
    done <<< "$gpu_lines"
    # Export global variables
    unset mgpu_manufacturer sgpu_manufacturer tgpu_manufacturer
    if [[ -n "$__var1" ]]; then mgpu_manufacturer=$__var1; fi
    if [[ -n "$__var2" ]]; then sgpu_manufacturer=$__var2; fi
    if [[ -n "$__var3" ]]; then tgpu_manufacturer=$__var3; fi
}