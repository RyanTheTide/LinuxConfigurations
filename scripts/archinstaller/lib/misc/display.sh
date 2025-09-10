#!/usr/bin/env bash

display_configuration() {
    __var="${disk%p}"
    clear
    # shellcheck disable=SC2154
    cat <<EOF
Current Configuration

Disk Information:
    Disk: ${__var}
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
$( [[ $is_virtualization -eq 1 && "$hypervisor_type" != "none" ]] && printf '    Virtualization/Hypervisor: %s\n' "$hypervisor_type" )
    CPU Manufacturer: ${cpu_manufacturer}
    Microcode Enabled: $([[ ${is_microcode} -eq 1 ]] && echo "yes" || echo "no")
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
