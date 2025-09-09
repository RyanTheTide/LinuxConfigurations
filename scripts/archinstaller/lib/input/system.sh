#!/usr/bin/env bash

# System input script gets various system settings:
# - locale & keymap : system locale and keyboard layout
# - dual-boot mode : option to disable Windows bootloader
# - secure boot : option to enable Secure Boot
# - timezone : system timezone
# - hostname : system hostname
# - mirrors : option to set mirrors based on country

input_system() {
# Locale & Keymap
    local __var1 __var2
    is_refind=1

    if confirm "Are you within the USA?" ; then
        main_locale="en_US.UTF-8"
        secondary_locale=""
        keymap="us"
    else
        while true; do
            echo
            ask __var1 "Enter your main locale (e.g. en_AU)" "en_AU"
            __var1="${__var1//[[:space:]]/}"
            if [[ "$__var1" =~ ^[a-z]{2}_[A-Z]{2}$ ]]; then
                # shellcheck disable=SC2034
                main_locale="${__var1}.UTF-8"
                # shellcheck disable=SC2034
                secondary_locale="en_US.UTF-8"
                break
            else
                log_warn "$__var1 is an invalid locale. Please try again."
            fi
        done
        while true; do
            ask __var2 "Enter your keymap (e.g. us, uk)" "us"
            __var2="${__var2,,}"
            __var2="${__var2//[[:space:]]/}"
            if localectl list-keymaps | grep -qx -- "$__var2"; then
                # shellcheck disable=SC2034
                keymap="$__var2"
                break
            else
                log_warn "$__var2 is an invalid keymap. Please try again."
            fi
        done    
    fi
# Dual-boot mode
    if confirm "Would you like to enable dual-boot mode (Windows)?" ; then
        # shellcheck disable=SC2034
        no_windows=0
    else
        # shellcheck disable=SC2034
        no_windows=1
    fi
    echo
# Secure Boot
    if [[ ${is_secureboot:-0} -eq 1 ]]; then
        say "Secure Boot detected in Setup Mode."
        if confirm "Would you like to enable Secure Boot?"; then
            # shellcheck disable=SC2034
            is_secureboot=1
        else
            # shellcheck disable=SC2034
            is_secureboot=0
        fi
        echo
    fi
# Timezone
    while true; do
        ask timezone "Enter your timezone (e.g. Australia/Sydney)" "Australia/Sydney"
        timezone="${timezone//[[:space:]]/}"
        if [[ -e "/usr/share/zoneinfo/$timezone" ]]; then
            # shellcheck disable=SC2034
            country="${timezone%%/*}"
            break
        else
            log_warn "$timezone is an invalid timezone. Please try again."
        fi
    done
# Hostname
    while true; do
        ask hostname "Enter your hostname (e.g. ArchLinux)" "ArchLinux"
        # shellcheck disable=SC2154
        if [[ "$hostname" =~ ^([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?)(\.([A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?))*$ ]]; then
            break
        else
            log_warn "$hostname is an invalid hostname. Please try again."
        fi
    done
# Mirrors
    if confirm "Do you wish to set mirrors based on $country?" ; then
        is_mirrors=1
    else
        is_mirrors=0
    fi
    echo
# Microcode
    if confirm "Would you like to install CPU microcode?" ; then
        is_microcode=1
    else
        is_microcode=0
    fi
    echo
}
