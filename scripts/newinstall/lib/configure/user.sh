#!/usr/bin/env bash

# User configuration script sets up various user related files:
# - newuser : new user (including password and description/full name)
# - rootpassword : root account password
# - sudoers : allow wheel group to use sudo

configure_accounts() {
    log_info "Configuring user accounts..."
    # shellcheck disable=SC2154
    arch-chroot /mnt useradd -c "${newuserdescription}" -m -G wheel -s /usr/bin/zsh "${newusername}" > /dev/null 2>&1
    # shellcheck disable=SC2154
    echo "${newusername}:${newuserpassword}" | chpasswd --root /mnt > /dev/null 2>&1
    # shellcheck disable=SC2154
    echo "root:${rootpassword}" | chpasswd --root /mnt > /dev/null 2>&1
    arch-chroot /mnt sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers > /dev/null 2>&1
}
