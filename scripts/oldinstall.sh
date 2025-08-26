#!/usr/bin/env bash
set -euo pipefail

# ---------------------------
# --- Basic Configuration ---
# ---------------------------
LOCALE="en_AU.UTF-8"
KEYMAP="us"
COUNTRY="Australia"
REGION="Sydney"
# Advanced Configuration Options available on lines 63-72
# ---------------------------

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Intro & Confirm Current Configuration
clear
echo "Welcome to the Arch Linux Installer by RyanTheTide!"
cat <<EOF
Current Static Configuration:
  Locale   : ${LOCALE}
  Keymap   : ${KEYMAP}
  Country  : ${COUNTRY}
  Region   : ${REGION}
EOF
read -r -p "Continue with current configuration? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted. Edit the script Configuration."
    exit 1
fi

# Device Input
read -r -p "Enter device identifier (e.g. /dev/nvme0n1): " DEVICE
if [[ ! -b "$DEVICE" ]]; then
    echo "Error: Device $DEVICE does not exist!"
    exit 1
fi
DISK_SIZE=$(lsblk -bno SIZE "${DEVICE}" | head -n1)
DISK_SIZE_MIB=$((DISK_SIZE / 1024 / 1024))
echo "Device: ${DEVICE} (${DISK_SIZE_MIB} MiB)"
# Hostname Input
read -r -p "Enter hostname: " HOSTNAME
echo "Hostname: ${HOSTNAME}"
# Root Password Input
read -r -s -p "Enter root password: " ROOTPASS
echo
echo "Root Password set"
# Account Input
read -r -p "Enter username: " USERNAME
if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
    echo "Error: Invalid username format!"
    exit 1
fi
echo "Username: ${USERNAME}"
read -r -s -p "Enter user password: " USERPASS
echo
echo "User Password set"

# -------------------------------------------
# -------- Advanced Configuration  ----------
# -------------------------------------------
EFI_END=2049
MSR_END=$((EFI_END + 16))
REMAIN_START=${MSR_END}
REMAIN_SIZE=$((DISK_SIZE_MIB - REMAIN_START))
HALF_SIZE=$((REMAIN_SIZE / 2))
WIN_END=$((REMAIN_START + HALF_SIZE))
# -------------------------------------------
# Confirm Final Configuration
clear
cat <<EOF
Current Configuration:
  Locale   : ${LOCALE}
  Keymap   : ${KEYMAP}
  Country  : ${COUNTRY}
  Region   : ${REGION}
  Device   : ${DEVICE}
  Hostname : ${HOSTNAME}
  Username : ${USERNAME}

WARNING: This will completely wipe ${DEVICE}!
Partition layout:
  - 2GB EFI System
  - 16MB Microsoft Reserved
  - ~$((HALF_SIZE / 1024))GB Windows
  - ~$((HALF_SIZE / 1024))GB Arch Linux
EOF
read -r -p "Continue? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi
# Partition the disk
echo "Creating partitions..."
parted -s "${DEVICE}" mklabel gpt
parted -s "${DEVICE}" mkpart primary fat32 1MiB ${EFI_END}MiB
parted -s "${DEVICE}" mkpart primary ${EFI_END}MiB ${MSR_END}MiB
parted -s "${DEVICE}" mkpart primary ntfs ${MSR_END}MiB ${WIN_END}MiB
parted -s "${DEVICE}" mkpart primary btrfs ${WIN_END}MiB 100%
parted -s "${DEVICE}" set 1 esp on
parted -s "${DEVICE}" set 2 msftres on
parted -s "${DEVICE}" set 3 msftdata on
# Format the partitions
echo "Formatting partitions..."
partprobe "${DEVICE}"
if [[ ! -b "${DEVICE}p1" ]] || [[ ! -b "${DEVICE}p4" ]]; then
    echo "Partitions not found! Exiting."
    exit 1
fi
udevadm settle
sleep 2
mkfs.fat -F 32 "${DEVICE}p1"
mkfs.btrfs -f "${DEVICE}p4"
echo "Partitions formatted!"
# Get PARTUUID
PARTUUID=$(blkid -s PARTUUID -o value "${DEVICE}p4")


# Create Btrfs subvolumes
echo "Creating Btrfs subvolumes..."
mount "${DEVICE}p4" /mnt
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@home
umount /mnt
# Mount Btrfs subvolumes with compression
echo "Mounting Btrfs subvolumes..."
mount -o compress=zstd:1,subvol=@ "${DEVICE}p4" /mnt
mkdir -p /mnt/.snapshots
mkdir -p /mnt/var/log
mkdir -p /mnt/home
mount -o compress=zstd:1,subvol=@snapshots "${DEVICE}p4" /mnt/.snapshots
mount -o compress=zstd:1,subvol=@log "${DEVICE}p4" /mnt/var/log
mount -o compress=zstd:1,subvol=@home "${DEVICE}p4" /mnt/home
# Mount the EFI system partition
echo "Creating EFI mount point..."
mkdir -p /mnt/efi
mount "${DEVICE}p1" /mnt/efi
echo "EFI system partition mounted!"

# Install the base system
echo "Installing base system (this may take a while)..."
pacstrap -K /mnt base linux linux-firmware
echo "Base system installed! Configuring the rest of the system..."
# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
# Setup the hostname, hosts, locale, keymap and timezone
echo "${HOSTNAME}" > /mnt/etc/hostname
cat <<EOF > /mnt/etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
echo "${LOCALE} UTF-8" > /mnt/etc/locale.gen
echo "en_US.UTF-8 UTF-8" >> /mnt/etc/locale.gen
echo LANG=${LOCALE} > /mnt/etc/locale.conf
echo KEYMAP=${KEYMAP} > /mnt/etc/vconsole.conf
arch-chroot /mnt locale-gen
arch-chroot /mnt ln -sf "/usr/share/zoneinfo/${COUNTRY}/${REGION}" /etc/localtime
arch-chroot /mnt hwclock --systohc
echo "System configured!"
# Install additional packages
echo "Installing additional packages..."
arch-chroot /mnt pacman -S --noconfirm \
    intel-ucode \
    base-devel \
    btrfs-progs \
    efibootmgr refind \
    networkmanager \
    bluez bluez-utils \
    mesa \
    pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber \
    nano neovim \
    sudo \
    zsh zsh-completions zsh-autosuggestions zsh-syntax-highlighting \
    git \
    reflector \
    fastfetch \
    cups \
    gnome
echo "Additional packages installed!"

# Setup accounts
echo "Setting up user accounts..."
echo "root:${ROOTPASS}" | chpasswd --root /mnt
arch-chroot /mnt useradd -m -G wheel -s /usr/bin/zsh "${USERNAME}"
echo "${USERNAME}:${USERPASS}" | chpasswd --root /mnt
arch-chroot /mnt sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
# Run reflector
echo "Running reflector..."
arch-chroot /mnt reflector --country ${COUNTRY} --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Enable services
echo "Enabling services..."
arch-chroot /mnt systemctl enable NetworkManager
arch-chroot /mnt systemctl enable bluetooth
arch-chroot /mnt systemctl enable cups
arch-chroot /mnt systemctl enable systemd-timesyncd
arch-chroot /mnt systemctl enable fstrim.timer
arch-chroot /mnt systemctl enable reflector.timer
arch-chroot /mnt systemctl enable gdm

# Install rEFInd
echo "Installing rEFInd..."
arch-chroot /mnt refind-install
cat >> /mnt/boot/refind_linux.conf <<EOF
"Boot using default options"     "root=PARTUUID=${PARTUUID} rw add_efi_memmap initrd=boot\initramfs-%v.img initrd=boot\intel-ucode.img"
"Boot using fallback initramfs"  "root=PARTUUID=${PARTUUID} rw add_efi_memmap initrd=boot\initramfs-%v-fallback.img initrd=boot\intel-ucode.img"
"Boot to terminal"               "root=PARTUUID=${PARTUUID} rw add_efi_memmap systemd.unit=multi-user.target initrd=boot\intel-ucode.img"
EOF
