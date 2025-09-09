#!/usr/bin/env bash

install_virtualization_tools() {
    case "$hypervisor_type" in
       oracle)
            arch-chroot /mnt pacman --noconfirm -S virtualbox-guest-utils
            is_virtualization_virtualbox=1
            ;;
        vmware)
            arch-chroot /mnt pacman --noconfirm -S open-vm-tools
            is_virtualization_vmware=1
            ;;
        microsoft)
            arch-chroot /mnt pacman --noconfirm -S hyperv
            is_virtualization_hyperv=1
            ;;
        qemu)
            arch-chroot /mnt pacman --noconfirm -S qemu-guest-agent
            is_virtualization_qemu=1
            ;;
    esac
}