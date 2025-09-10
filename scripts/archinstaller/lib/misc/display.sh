#!/usr/bin/env bash

display_configuration() {
    local __var1="${disk%p}" virt_line="" gpu_line=""
    if [[ ${is_virtualization:-0} -eq 1 && -n ${hypervisor_type:-} && "${hypervisor_type,,}" != "none" ]]; then
        virt_line=$(printf '    Virtualization/Hypervisor: %s\n' "$hypervisor_type")
    fi
    if [[ ${is_igpu:-0} -eq 1 && -n ${igpu_manufacturer:-} && "${igpu_manufacturer,,}" != "none" ]]; then
        gpu_line="    iGPU Manufacturer: ${igpu_manufacturer}\n"
    fi
    if [[ ${is_gpu:-0} -eq 1 && -n ${mgpu_manufacturer:-} && "${mgpu_manufacturer,,}" != "none" ]]; then
        gpu_line+="    dGPU Manufacturer(s): ${mgpu_manufacturer}"
        [[ -n ${sgpu_manufacturer:-} && "${sgpu_manufacturer,,}" != "none" ]] && gpu_line+=", ${sgpu_manufacturer}"
        [[ -n ${tgpu_manufacturer:-} && "${tgpu_manufacturer,,}" != "none" ]] && gpu_line+=", ${tgpu_manufacturer}"
        gpu_line+="\n"
    fi
    clear
    # shellcheck disable=SC2154
    cat <<EOF
Current Configuration

Disk Information:
    Disk: ${__var1}
    SSD Detected: $([[ ${is_ssd} -eq 1 ]] && echo "yes" || echo "no")

System Information:
    Main Locale: ${main_locale}
    Secondary Locale: ${secondary_locale}
    Keymap: ${keymap}
    Timezone: ${timezone}
    Country: ${country}
    Hostname: ${hostname}
    GUI: ${set_gui}

Boot Information:
${virt_line}    CPU Manufacturer: ${cpu_manufacturer}
${gpu_line}    Microcode Enabled: $([[ ${is_microcode} -eq 1 ]] && echo "yes" || echo "no")
    Dual-Boot Enabled: $([[ ${no_windows} -eq 0 ]] && echo "yes" || echo "no")
    Secure Boot Enabled: $([[ ${is_secureboot} -eq 1 ]] && echo "yes" || echo "no")
    Bootloader: ${bootloader}

User Information:
    New Username: ${newusername}
    New User Full Name: ${newuserdescription}

EOF
}

display_warning() {
    local __var1 __var2
    __var2="${disk%p}"
    cat <<EOF
==============================================================================
WARNING: Proceeding will ERASE ALL DATA on the selected disk ($__var2).
Ensure you have backed up any important data before continuing.
==============================================================================
EOF
    read -rp "Type YES to confirm and continue: " __var1
    if [[ "$__var1" != "YES" ]]; then
        log_fatal "Confirmation not received. Installation aborted."
    fi
    echo
}
