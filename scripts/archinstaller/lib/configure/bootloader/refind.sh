#!/usr/bin/env bash
# shellcheck disable=SC2154

# rEFInd configuration script sets up the rEFInd bootloader.

set_refind() {
    arch-chroot /mnt pacman -S --noconfirm refind efibootmgr > /dev/null 2>&1
	log_info "Configuring rEFInd bootmanager..."
	arch-chroot /mnt refind-install > /dev/null 2>&1
	rm -f /mnt/boot/refind_linux.conf > /dev/null 2>&1
	touch /mnt/boot/refind_linux.conf
 	if [[ ${is_microcode} -eq 1 ]]; then
  		cat > /mnt/boot/refind_linux.conf <<EOF
"Standard Boot"  "root=PARTUUID=${root_uuid} rw add_efi_memmap quiet rootflags=subvol=@ initrd=@\\boot\\${cpu_manufacturer}-ucode.img initrd=@\\boot\\initramfs-linux.img"
"Fallback Boot"  "root=PARTUUID=${root_uuid} rw add_efi_memmap rootflags=subvol=@ initrd=@\\boot\\${cpu_manufacturer}-ucode.img initrd=@\\boot\\initramfs-linux-fallback.img"
"Terminal Boot"  "root=PARTUUID=${root_uuid} rw add_efi_memmap rootflags=subvol=@ initrd=@\\boot\\${cpu_manufacturer}-ucode.img initrd=@\\boot\\initramfs-linux.img systemd.unit=multi-user.target"
EOF
	else
		cat > /mnt/boot/refind_linux.conf <<EOF
"Standard Boot"  "root=PARTUUID=${root_uuid} rw add_efi_memmap quiet rootflags=subvol=@ initrd=@\\boot\\initramfs-linux.img"
"Fallback Boot"  "root=PARTUUID=${root_uuid} rw add_efi_memmap rootflags=subvol=@ initrd=@\\boot\\initramfs-linux-fallback.img"
"Terminal Boot"  "root=PARTUUID=${root_uuid} rw add_efi_memmap rootflags=subvol=@ initrd=@\\boot\\initramfs-linux.img systemd.unit=multi-user.target"
EOF
	fi
	# Copy custom rEFInd configuration/theme from repo
	mv /mnt/efi/EFI/refind/refind.conf /mnt/efi/EFI/refind/refind.conf.bak
	cp -r /mnt/var/tmp/LinuxConfigurations/refind /mnt/efi/EFI/
    log_success "rEFInd bootmanager configured."
}
