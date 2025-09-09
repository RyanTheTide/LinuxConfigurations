#!/usr/bin/env bash

install_virtualization_tools() {
    case "$hypervisor_type" in
       oracle)
            arch-chroot /mnt pacman --noconfirm -S virtualbox-guest-utils > /dev/null 2>&1
            is_virtualization_virtualbox=1
            ;;
        vmware)
            arch-chroot /mnt pacman --noconfirm -S open-vm-tools > /dev/null 2>&1
            is_virtualization_vmware=1
            ;;
        microsoft)
            arch-chroot /mnt pacman --noconfirm -S hyperv > /dev/null 2>&1
            is_virtualization_hyperv=1
            ;;
        qemu)
            arch-chroot /mnt pacman --noconfirm -S qemu-guest-agent > /dev/null 2>&1
            is_virtualization_qemu=1
            ;;
    esac
}