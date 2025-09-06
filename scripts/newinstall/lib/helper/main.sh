#!/usr/bin/env bash

# Main helper script for requiring root, and ending the installation process.

require_root() {
	[[ $EUID -eq 0 ]] || log_fatal "This script must be run as root"
}

script_end() {
	rm -rf /mnt/var/tmp/LinuxConfigurations
	log_success "Installation complete!"
}