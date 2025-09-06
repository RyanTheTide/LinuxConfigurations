#!/usr/bin/env bash

display_configuration() {
    clear
    # shellcheck disable=SC2154
    cat <<EOF
====================================================================
Current Configuration

Disk Information:
Disk: ${disk}
Is SSD: $([[ ${is_ssd} -eq 1 ]] && echo "yes" || echo "no")

System Information:
Main Locale: ${main_locale}
Secondary Locale: ${secondary_locale}
Keymap: ${keymap}
Timezone: ${timezone}
Country: ${country}
Hostname: ${hostname}

Boot Information:
CPU Manufacturer: ${cpu_manufacturer}
Dual-Boot Enabled: $([[ ${no_windows} -eq 0 ]] && echo "yes" || echo "no")
Secure Boot Enabled: $([[ ${is_secureboot} -eq 1 ]] && echo "yes" || echo "no")
rEFInd Enabled: $([[ ${is_refind} -eq 1 ]] && echo "yes" || echo "no")

User Information:
New Username: ${newusername}
New User Password: (hidden)
New User Full Name: ${newuserdescription}
Root Password: (hidden)
====================================================================
EOF
}

display_warning() {
    local __var
    cat <<EOF
====================================================================
WARNING: Proceeding will ERASE ALL DATA on the selected disk ($disk).
Ensure you have backed up any important data before continuing.
============================================================
EOF
    read -rp "Type YES to confirm and continue: " __var
    if [[ "$__var" != "YES" ]]; then
        log_fatal "Confirmation not received. Installation aborted."
    fi
}
