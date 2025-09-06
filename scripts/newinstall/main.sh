#!/usr/bin/env bash
set -Eeuo pipefail

# Load all library scripts
__script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
shopt -s globstar nullglob
for f in "$__script_dir"/lib/**/*.sh; do
	# shellcheck disable=SC1090
	source "$f"
done

trap 'umount -R /mnt 2>/dev/null || true' EXIT
trap 'log_fatal "Error $?: command '\''${BASH_COMMAND}'\'' at ${BASH_SOURCE[0]}:${LINENO}"' ERR

# shellcheck disable=SC2154
main() {
	require_root
	input_welcome
	input_disk
	input_system
	input_user
	detect_cpu_manufacturer

	display_configuration
	display_warning

	create_partitions_layout
	create_partitions
	format_partitions
	create_btrfs_subvolumes
	mount_btrfs_subvolumes
	create_efi_volume
	mount_efi_volume

	if [[ ${is_mirrors} == 1 ]]; then
		set_mirrors
	fi
	install_base
	configure_system
	install_extra

	configure_accounts
	configure_shell
	configure_dotfiles

	configure_services
	set_refind
	if [[ ${is_secureboot} == 1 ]]; then
		set_secureboot
	fi

	script_end
}

main "$@"