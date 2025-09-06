#!/usr/bin/env bash

# System configuration script sets up various system files:
# - fstab : mount points
# - hostname : system hostname
# - hosts : static hostname resolution
# - locale/s : system locale settings
# - keymap : keyboard layout
# - timezone : system timezone

configure_system() {
    log_info "Configuring system..."
    genfstab -U /mnt >> /mnt/etc/fstab
    # shellcheck disable=SC2154
    echo "${hostname}" > /mnt/etc/hostname
cat <<EOF > /mnt/etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${hostname}.localdomain ${hostname}
EOF
    # shellcheck disable=SC2154
    echo "${main_locale} UTF-8" > /mnt/etc/locale.gen
    if [[ -n "${secondary_locale}" && "${secondary_locale}" != "${main_locale}" ]]; then
		echo "${secondary_locale} UTF-8" >> /mnt/etc/locale.gen
	fi
    echo LANG="${main_locale}" > /mnt/etc/locale.conf
    arch-chroot /mnt locale-gen > /dev/null 2>&1
    # shellcheck disable=SC2154
    echo KEYMAP="${keymap}" > /mnt/etc/vconsole.conf
    # shellcheck disable=SC2154
    arch-chroot /mnt ln -sf "/usr/share/zoneinfo/${timezone}" /etc/localtime
}