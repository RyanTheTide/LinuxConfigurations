#!/usr/bin/env bash
set -euo pipefail

# This script installs a base Arch Linux system ontop of a btrfs filesystem with rEFInd as the boot manager.
# The script will also partition the disk for dual-booting with Windows by creating the two windows specific partitions.
# It was designed for personal use, however if you wish to take pointers from it, please feel free to do so.
# This is not a comprehensive installation guide but rather a helper script, refer to the Arch Wiki for more information on latest installation advice. See below.
# https://wiki.archlinux.org/title/Installation_guide or run Installation_guide on your installer with a valid internet connection.
# Unfortunately, as of the creation of this script, the official archinstall script does not support my custom btrfs filesystem layout or rEFInd as a boot manager.
# Finally, you can use the official archinstall script for a better more official installation experience.
#
# The default configuration of this script will create the following partitions and format appropriately:
# Please note the MSR partition is required for Windows to boot properly, and is created automatically by the script so Windows doesn't have to.
# - 2 GiB - EFI System Partition (FAT32)
# - 16 MiB - Microsoft Reserved (MSR)
# - 50% of remainder - Microsoft Basic (NTFS)
# - 50% of remainder - Linux root x86-64 (BTRFS)
# And the following subvolumes on the Linux root x86-64:
# - @ (/)
# - @home (/home)
# - @snapshots (/.snapshots)
# - @cache (/var/cache)
# - @log (/var/log)
#
# Install Variables:
# TIMEZONE - the timezone you are in (e.g. Australia/Sydney).
# MLOCALE - the locale for the new system (e.g. en_AU.UTF-8).
# SLOCALE - the secondary locale for the new system (e.g. en_US.UTF-8).
# KEYMAP - the keyboard layout (e.g. us).
# TDISK - the disk to install Arch Linux on (e.g. /dev/sda or /dev/nvme0n1).
# HOSTNAME - the hostname for the new system (e.g. ArchLinux).
# ROOTPASS - the password for the root user (e.g. supersecretpass).
# USERNAME - the username for the new user (e.g. ryan).
# USERPASS - the password for the new user (e.g. secretpass).
# USERFULLNAME - the full name for the new user (e.g. Ryan Murray).
# CPUTYPE - the CPU type for the new system (e.g. intel or amd). Used for setting ucode.
# COUNTRY - the country for the new system (e.g. Australia). Used for setting mirrors with reflector. Automatically obtained from timezone.


# ----------------------------------------------------- Start Script -------------------------------------------------------\
# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi
# Welcome user
clear
echo -e "Welcome to the Arch Linux Installer by RyanTheTide!\n\nLet's start by selecting the target disk for installation.\n"

# Show and input target disk
echo "------------------------------------------------------"
lsblk -dn -o NAME,SIZE,MODEL | grep -v '^loop' | awk '{print "/dev/" $1, "-", $2, "-", substr($0, index($0,$3))}'
echo -e "------------------------------------------------------\n"
read -r -p "Enter device identifier (e.g. /dev/nvme0n1): " TDISK
if [[ ! -b "$TDISK" ]]; then
    echo "Error: Device $TDISK does not exist!"
    exit 1
fi
if [[ "$TDISK" =~ nvme ]]; then
    PART="${TDISK}p"
else
    PART="${TDISK}"
fi
clear
# Input system configuration
while true; do
    read -r -p "Enter CPU type (amd/intel): " CPUTYPE
    case "$CPUTYPE" in
        amd|intel)
            break
            ;;
        *)
            echo "Invalid input. Please type exactly 'amd' or 'intel'."
            ;;
    esac
done
echo
read -r -p "Enter hostname (e.g. ArchLinux): " HOSTNAME
echo
read -r -s -p "Enter root password (e.g. supersecretpassword): " ROOTPASS
echo -e "\n"
read -r -p "Enter username (e.g. ryan): " USERNAME
echo
read -r -s -p "Enter user password (e.g. secretpassword): " USERPASS
echo -e "\n"
read -r -p "Enter full name (e.g. Ryan Murray): " USERFULLNAME
# --------------------------------------------------------------------------------------------------------------------------/
# -------------- System Configuration --------------\
TIMEZONE="Australia/Sydney"
MLOCALE="en_AU.UTF-8"
SLOCALE="en_US.UTF-8"
KEYMAP="us"
COUNTRY="${TIMEZONE%%/*}"
# ** AUTOMATION **
#TDISK="/dev/nvme0n1"
#HOSTNAME="ArchLinux"
#ROOTPASS="supersecretpassword"
#USERPASS="secretpassword"
# ****************
# Partition Size Variables:
DISKSIZE=$(lsblk -bno SIZE "${TDISK}" | head -n1)
DISKSIZE_MIB=$((DISKSIZE / 1024 / 1024))
EFIEND=2049
MSREND=$((EFIEND + 16))
REMAINSTART=${MSREND}
REMAINSIZE=$((DISKSIZE_MIB - REMAINSTART))
HALFSIZE=$((REMAINSIZE / 2))
WINEND=$((REMAINSTART + HALFSIZE))
# --------------------------------------------------/
# ------------------------------------------------------------------\
# Show current configuration
clear
cat <<EOF
Confirm the following settings are correct before continuing.

Current Zone Configuration:
  Timezone             : ${TIMEZONE}
  Main Locale          : ${MLOCALE}
  Secondary Locale     : ${SLOCALE}
  Keymap               : ${KEYMAP}

Current Device Configuration:
  Disk                 : ${TDISK}
  CPU Type             : ${CPUTYPE}
  Hostname             : ${HOSTNAME}
  Username             : ${USERNAME}

EOF
#cat <<EOF
#Current Password Configuration:
#    Root Password        : ${ROOTPASS}
#    User Password        : ${USERPASS}
#
#EOF
cat <<EOF
Partition layout:
  - 2GB EFI System
  - 16MB Microsoft Reserved
  - ~$((HALFSIZE / 1024))GB Windows
  - ~$((HALFSIZE / 1024))GB Arch Linux

WARNING: This will completely wipe ${TDISK}!

EOF
read -r -p "Continue with current configuration? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi
# ------------------------------------------------------------------/
# ----------------------------------- Partitioning -----------------------------------------/
# Partition the disk
echo -e "\nCreating partitions...\n"
parted -s "${TDISK}" mklabel gpt
parted -s "${TDISK}" mkpart primary fat32 1MiB ${EFIEND}MiB
parted -s "${TDISK}" set 1 esp on
parted -s "${TDISK}" name 1 "EFI"
parted -s "${TDISK}" mkpart primary ${EFIEND}MiB ${MSREND}MiB
parted -s "${TDISK}" set 2 msftres on
parted -s "${TDISK}" name 2 "MSR"
parted -s "${TDISK}" mkpart primary ntfs ${MSREND}MiB ${WINEND}MiB
parted -s "${TDISK}" set 3 msftdata on
parted -s "${TDISK}" name 3 "Windows"
parted -s "${TDISK}" mkpart primary btrfs ${WINEND}MiB 100%
parted -s "${TDISK}" name 4 "Arch"
# Format the partitions
echo -e "Formatting partitions...\n"
partprobe "${TDISK}" > /dev/null 2>&1
udevadm settle > /dev/null 2>&1
sleep 2 > /dev/null 2>&1
if [[ ! -b "${PART}1" ]] || [[ ! -b "${PART}4" ]]; then
    echo "Partitions not found! Exiting."
    exit 1
fi
mkfs.fat -F 32 "${PART}1" > /dev/null 2>&1
mkfs.ntfs -f "${PART}3" > /dev/null 2>&1
mkfs.btrfs -f "${PART}4" > /dev/null 2>&1
echo -e "Finished creating filesystems!\n"
# Get PARTUUID
ROOTPARTUUID=$(blkid -s PARTUUID -o value "${PART}4")
# Create Btrfs subvolumes
echo -e "Creating & mounting Btrfs subvolumes...\n"
mount "${PART}4" /mnt > /dev/null 2>&1
btrfs subvolume create /mnt/@ > /dev/null 2>&1
btrfs subvolume create /mnt/@home > /dev/null 2>&1
btrfs subvolume create /mnt/@snapshots > /dev/null 2>&1
btrfs subvolume create /mnt/@cache > /dev/null 2>&1
btrfs subvolume create /mnt/@log > /dev/null 2>&1
umount /mnt > /dev/null 2>&1
# Mount Btrfs subvolumes with compression
mount -o compress=zstd:1,subvol=@ "${PART}4" /mnt > /dev/null 2>&1
mkdir -p /mnt/home > /dev/null 2>&1
mkdir -p /mnt/.snapshots > /dev/null 2>&1
mkdir -p /mnt/var/cache > /dev/null 2>&1
mkdir -p /mnt/var/log > /dev/null 2>&1
mount -o compress=zstd:1,subvol=@home "${PART}4" /mnt/home > /dev/null 2>&1
mount -o compress=zstd:1,subvol=@snapshots "${PART}4" /mnt/.snapshots > /dev/null 2>&1
mount -o compress=zstd:1,subvol=@cache "${PART}4" /mnt/var/cache > /dev/null 2>&1
mount -o compress=zstd:1,subvol=@log "${PART}4" /mnt/var/log > /dev/null 2>&1
# Create & mount EFI partition
echo -e "Creating & mounting EFI volume...\n"
mkdir -p /mnt/efi
mount "${PART}1" /mnt/efi
echo -e "All volumes initialized!\n"
# ------------------------------------------------------------------------------------------/
# -------------------------------------------------- Packages -------------------------------------------------------\
# Install base system
echo -e "Installing base system (this may take a while)...\n"
pacstrap -K /mnt base linux linux-firmware > /dev/null 2>&1
echo -e "Base system installed!\n"
# Generate system files
echo -e "Generating system files...\n"
genfstab -U /mnt >> /mnt/etc/fstab
echo "${HOSTNAME}" > /mnt/etc/hostname
cat <<EOF > /mnt/etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
echo "${MLOCALE} UTF-8" > /mnt/etc/locale.gen
echo "${SLOCALE} UTF-8" >> /mnt/etc/locale.gen
echo LANG=${MLOCALE} > /mnt/etc/locale.conf
arch-chroot /mnt locale-gen > /dev/null 2>&1
echo KEYMAP=${KEYMAP} > /mnt/etc/vconsole.conf
arch-chroot /mnt ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
# Install additional packages
echo -e "Installing additional packages (this may take a while)...\n"
arch-chroot /mnt pacman -Sy --noconfirm \
    "${CPUTYPE}"-ucode \
    base-devel  \
    btrfs-progs \
    efibootmgr refind \
    networkmanager \
    bluez \
    mesa \
    nano \
    sudo \
    zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting \
    git unzip \
    reflector \
    fastfetch > /dev/null 2>&1
# Set mirrors with reflector
echo -e "Setting mirrors...\n"
arch-chroot /mnt reflector --country "${COUNTRY}" --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist > /dev/null 2>&1
# -------------------------------------------------------------------------------------------------------------------/
# ------------------------------------------------------------------------------ User Accounts Setup --------------------------------------------------------------------------------\
# Setup accounts
echo -e "Setting up user account...\n"
echo "root:${ROOTPASS}" | chpasswd --root /mnt > /dev/null 2>&1
arch-chroot /mnt useradd -c "${USERFULLNAME}" -m -G wheel -s /usr/bin/zsh "${USERNAME}" > /dev/null 2>&1
echo "${USERNAME}:${USERPASS}" | chpasswd --root /mnt > /dev/null 2>&1
arch-chroot /mnt sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers > /dev/null 2>&1
# Setup Shell
echo -e "Setting up Shell...\n"
arch-chroot /mnt su - "${USERNAME}" -s /bin/bash <<'EOL'
set -euo pipefail
touch "$HOME/.zshrc" > /dev/null 2>&1
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash -s -- --unattended > /dev/null 2>&1
curl -s https://ohmyposh.dev/install.sh | bash -s > /dev/null 2>&1
"$HOME/.local/bin/oh-my-posh" font install meslo > /dev/null 2>&1
mv "$HOME/.zshrc" "$HOME/.zshrc.bak" > /dev/null 2>&1
EOL
# Setup Dotfiles
echo -e "Configuring Shell...\n"
arch-chroot /mnt su - "${USERNAME}" -s /bin/bash <<'EOL'
set -euo pipefail
cd "/var/tmp" > /dev/null 2>&1
git clone https://github.com/RyanTheTide/LinuxConfigurations.git > /dev/null 2>&1
cd LinuxConfigurations > /dev/null 2>&1
cp -r dotfiles/. "$HOME" > /dev/null 2>&1
history -c > /dev/null 2>&1
EOL
# -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------/
# ----------------- Enable Services -------------\
# Enable services
echo -e "Enabling services...\n"
arch-chroot /mnt systemctl enable fstrim.timer > /dev/null 2>&1
arch-chroot /mnt systemctl enable NetworkManager > /dev/null 2>&1
arch-chroot /mnt systemctl enable reflector.timer > /dev/null 2>&1
# -----------------------------------------------/
# ----------------------------------------------------------------------- Setup Boot Manager --------------------------------------------------------------------------------------------------\
# rEFInd Installation
echo -e "Installing rEFInd...\n"
arch-chroot /mnt refind-install  > /dev/null 2>&1
rm /mnt/boot/refind_linux.conf > /dev/null 2>&1
touch /mnt/boot/refind_linux.conf > /dev/null 2>&1
cat > /mnt/boot/refind_linux.conf <<EOF
"Standard Boot"  "root=PARTUUID=${ROOTPARTUUID} rw add_efi_memmap quiet rootflags=subvol=@ initrd=@\\boot\\${CPUTYPE}-ucode.img initrd=@\\boot\\initramfs-linux.img"
"Fallback Boot"  "root=PARTUUID=${ROOTPARTUUID} rw add_efi_memmap rootflags=subvol=@ initrd=@\\boot\\${CPUTYPE}-ucode.img initrd=@\\boot\\initramfs-linux-fallback.img"
"Terminal Boot"  "root=PARTUUID=${ROOTPARTUUID} rw add_efi_memmap rootflags=subvol=@ initrd=@\\boot\\${CPUTYPE}-ucode.img initrd=@\\boot\\initramfs-linux.img systemd.unit=multi-user.target"
EOF
# Copy custom rEFInd configuration
mv /mnt/efi/EFI/refind/refind.conf /mnt/efi/EFI/refind/refind.conf.bak
cp -r /mnt/var/tmp/LinuxConfigurations/refind /mnt/efi/EFI/
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------/
# Tidy Up & Success!
rm -rf /mnt/var/tmp/LinuxConfigurations
echo -e "Installation complete!\n"