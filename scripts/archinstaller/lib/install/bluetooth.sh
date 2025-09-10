#!/usr/bin/env bash

install_bluetooth() {
    log_info "Installing Bluetooth support..."
    pacstrap -K /mnt bluez bluez-utils >/dev/null 2>&1
    log_success "Bluetooth support installed."
}