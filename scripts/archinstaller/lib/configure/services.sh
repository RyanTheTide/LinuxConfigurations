#!/usr/bin/env bash
# shellcheck disable=SC2154

# Services configuration script sets up various systemd services:
# - fstrim.timer : for SSDs (set by is_ssd variable)
# - NetworkManager : network management
# - reflector.timer : to update mirrors (set by is_mirrors variable)
# - virtualization tools (set by is_virtualization and related variables)

configure_services() {
    log_info "Configuring services..."
    if [[ "${is_ssd}" == 1 ]]; then
        systemctl --root=/mnt enable fstrim.timer >/dev/null 2>&1
    fi
    systemctl --root=/mnt enable NetworkManager >/dev/null 2>&1
    if [[ "$is_mirrors" == 1 ]]; then
        systemctl --root=/mnt enable reflector.timer >/dev/null 2>&1
    fi
    if [[ "$is_virtualization" == 1 ]]; then
        if [[ ${is_virtualization_virtualbox:-0} -eq 1 ]]; then
            systemctl --root=/mnt enable vboxservice.service >/dev/null 2>&1
        fi
        if [[ ${is_virtualization_vmware:-0} -eq 1 ]]; then
            systemctl --root=/mnt enable vmtoolsd.service vmware-vmblock-fuse.service >/dev/null 2>&1
        fi
        if [[ ${is_virtualization_hyperv:-0} -eq 1 ]]; then
            systemctl --root=/mnt enable hv_kvp_daemon.service hv_vss_daemon.service >/dev/null 2>&1
        fi
        if [[ ${is_virtualization_qemu:-0} -eq 1 ]]; then
            systemctl --root=/mnt enable qemu-guest-agent.service >/dev/null 2>&1
        fi
    fi
    if [[ "$is_gui" == 1 ]]; then
        if [[ "$is_gui_gnome" == 1 ]]; then
            systemctl --root=/mnt enable gdm.service >/dev/null 2>&1
        elif [[ "$is_gui_kde" == 1 ]]; then
            systemctl --root=/mnt enable sddm.service >/dev/null 2>&1
        fi
    fi
    log_success "Services configured."
}

