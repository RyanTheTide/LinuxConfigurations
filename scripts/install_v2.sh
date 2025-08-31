#!/usr/bin/env bash
# Arch Linux installer (v1.1, refactor into functions)
# Preserves behavior of install_v1.sh while organizing code for easier changes.

set -euo pipefail

######################################################################
# Helpers
######################################################################
log()  { printf "[INFO] %s\n" "$*"; }
warn() { printf "[WARN] %s\n" "$*" 1>&2; }
die()  { printf "[ERROR] %s\n" "$*" 1>&2; exit 1; }

trap 'die "Script aborted (line $LINENO)."' ERR

######################################################################
# Defaults (edit here for quick adjustments)
######################################################################
# Note: These are opinionated defaults; adjust as needed.
TIMEZONE="Australia/Sydney"
MLOCALE="en_AU.UTF-8 UTF-8 "
SLOCALE="en_US.UTF-8 UTF-8"
KEYMAP="us"

# Derived
COUNTRY="${TIMEZONE%%/*}"

# Feature toggles (can be set via CLI args)
DISABLE_WINDOWS=0   # when 1, no Windows/MSR partitions will be created

# User-supplied at runtime
TDISK=""         # e.g. /dev/nvme0n1
PART=""          # e.g. /dev/nvme0n1p or /dev/sda
CPUTYPE=""       # amd|intel
HOSTNAME=""      # e.g. ArchLinux
ROOTPASS=""      # e.g. supersecretpassword
USERNAME=""      # e.g. ryan
USERPASS=""      # e.g. secretpassword
USERFULLNAME=""  # e.g. Ryan Murray

# Computed sizes (MiB)
EFIEND=2049      # ~2GiB
MSREND=0         # EFIEND + 16
REMAINSTART=0    # MSREND
REMAINSIZE=0     # total - REMAINSTART
HALFSIZE=0       # REMAINSIZE / 2
WINEND=0         # REMAINSTART + HALFSIZE
ROOTIDX=4        # default root partition index (4 in dual-boot mode)

ROOTPARTUUID=""  # e.g. PARTUUID of root partition

######################################################################
# Input & validation
######################################################################
require_root() {
	[[ $EUID -eq 0 ]] || die "This script must be run as root"
}

parse_args() {
	# Accept args like: nowindows | nowin | --no-windows
	for arg in "$@"; do
		case "$arg" in
			nowindows|nowin|--no-windows)
				DISABLE_WINDOWS=1
				;;
		esac
	done
}

select_disk() {
	clear
	echo -e "Welcome to the Arch Linux Installer by RyanTheTide!\n\nLet's start by selecting the target disk for installation.\n"
	echo "------------------------------------------------------"
	lsblk -dn -o NAME,SIZE,MODEL | grep -v '^loop' | awk '{print "/dev/" $1, "-", $2, "-", substr($0, index($0,$3))}'
	echo -e "------------------------------------------------------\n"
	read -r -p "Enter device identifier (e.g. /dev/nvme0n1): " TDISK
	[[ -b "$TDISK" ]] || die "Device $TDISK does not exist!"
	if [[ "$TDISK" =~ nvme ]]; then
		PART="${TDISK}p"
	else
		PART="${TDISK}"
	fi
}

prompt_system_config() {
	clear
	while true; do
		read -r -p "Enter CPU type (amd/intel): " CPUTYPE
		case "$CPUTYPE" in
			amd|intel) break ;;
			*) echo "Invalid input. Please type exactly 'amd' or 'intel'." ;;
		esac
	done
	echo
	read -r -p "Enter hostname (e.g. ArchLinux): " HOSTNAME
	echo
	read -r -s -p "Enter root password (e.g. supersecretpassword): " ROOTPASS; echo
	echo
	read -r -p "Enter username (e.g. ryan): " USERNAME
	echo
	read -r -s -p "Enter user password (e.g. secretpassword): " USERPASS; echo
	echo
	read -r -p "Enter full name (e.g. Ryan Murray): " USERFULLNAME
	echo
	read -r -p "Are you within the USA? (yes/no): " INUSA
	case "${INUSA}" in
		y|Y|yes|YES)
			MLOCALE="en_US.UTF-8 UTF-8"
			SLOCALE=""
			;;
		*)
			read -r -p "Enter your main locale (e.g. en_AU): " INPUT_LOCALE
			INPUT_LOCALE=${INPUT_LOCALE%.UTF-8}
			MLOCALE="${INPUT_LOCALE}.UTF-8 UTF-8"
			SLOCALE="en_US.UTF-8 UTF-8"
			;;
	esac
}

compute_partition_layout() {
	local DISKSIZE DISKSIZE_MIB
	DISKSIZE=$(lsblk -bno SIZE "${TDISK}" | head -n1)
	DISKSIZE_MIB=$((DISKSIZE / 1024 / 1024))
	if [[ ${DISABLE_WINDOWS} -eq 1 ]]; then
		# No MSR/Windows; single BTRFS root after EFI
		MSREND=${EFIEND}
		REMAINSTART=${EFIEND}
		REMAINSIZE=$((DISKSIZE_MIB - REMAINSTART))
		HALFSIZE=0
		WINEND=${REMAINSTART}
		ROOTIDX=2
	else
		MSREND=$((EFIEND + 16))
		REMAINSTART=${MSREND}
		REMAINSIZE=$((DISKSIZE_MIB - REMAINSTART))
		HALFSIZE=$((REMAINSIZE / 2))
		WINEND=$((REMAINSTART + HALFSIZE))
		ROOTIDX=4
	fi
}

confirm_summary() {
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

Partition layout:
	- 2GB EFI System
$( [[ ${DISABLE_WINDOWS} -eq 1 ]] && echo "  - Entire remaining disk: Arch Linux (BTRFS)" || echo "  - 16MB Microsoft Reserved
	- ~$((HALFSIZE / 1024))GB Windows
	- ~$((HALFSIZE / 1024))GB Arch Linux" )

WARNING: This will completely wipe ${TDISK}!

EOF
	read -r -p "Continue with current configuration? (yes/no): " CONFIRM
	[[ "$CONFIRM" == "yes" ]] || die "Aborted."
}

######################################################################
# Partitioning & filesystems
######################################################################
partition_disk() {
	log "Creating partitions..."
	parted -s "${TDISK}" mklabel gpt
	parted -s "${TDISK}" mkpart primary fat32 1MiB ${EFIEND}MiB
	parted -s "${TDISK}" set 1 esp on
	parted -s "${TDISK}" name 1 "EFI"
	if [[ ${DISABLE_WINDOWS} -eq 1 ]]; then
		parted -s "${TDISK}" mkpart primary btrfs ${EFIEND}MiB 100%
		parted -s "${TDISK}" name 2 "Arch"
	else
		parted -s "${TDISK}" mkpart primary ${EFIEND}MiB ${MSREND}MiB
		parted -s "${TDISK}" set 2 msftres on
		parted -s "${TDISK}" name 2 "MSR"
		parted -s "${TDISK}" mkpart primary ntfs ${MSREND}MiB ${WINEND}MiB
		parted -s "${TDISK}" set 3 msftdata on
		parted -s "${TDISK}" name 3 "Windows"
		parted -s "${TDISK}" mkpart primary btrfs ${WINEND}MiB 100%
		parted -s "${TDISK}" name 4 "Arch"
	fi
}

format_filesystems() {
	log "Formatting partitions..."
	partprobe "${TDISK}" > /dev/null 2>&1 || true
	udevadm settle > /dev/null 2>&1 || true
	sleep 2 > /dev/null 2>&1 || true
	[[ -b "${PART}1" && -b "${PART}${ROOTIDX}" ]] || die "Partitions not found after create!"
	mkfs.fat -F 32 "${PART}1" > /dev/null 2>&1
	if [[ ${DISABLE_WINDOWS} -eq 0 ]]; then
		mkfs.ntfs -f "${PART}3" > /dev/null 2>&1
	fi
	mkfs.btrfs -f "${PART}${ROOTIDX}" > /dev/null 2>&1
	ROOTPARTUUID=$(blkid -s PARTUUID -o value "${PART}${ROOTIDX}")
}

create_btrfs_layout_and_mount() {
	log "Creating & mounting Btrfs subvolumes..."
	mount "${PART}${ROOTIDX}" /mnt > /dev/null 2>&1
	btrfs subvolume create /mnt/@ > /dev/null 2>&1
	btrfs subvolume create /mnt/@home > /dev/null 2>&1
	btrfs subvolume create /mnt/@snapshots > /dev/null 2>&1
	btrfs subvolume create /mnt/@cache > /dev/null 2>&1
	btrfs subvolume create /mnt/@log > /dev/null 2>&1
	umount /mnt > /dev/null 2>&1

	mount -o compress=zstd:1,subvol=@ "${PART}${ROOTIDX}" /mnt > /dev/null 2>&1
	mkdir -p /mnt/home /mnt/.snapshots /mnt/var/cache /mnt/var/log /mnt/efi > /dev/null 2>&1
	mount -o compress=zstd:1,subvol=@home "${PART}${ROOTIDX}" /mnt/home > /dev/null 2>&1
	mount -o compress=zstd:1,subvol=@snapshots "${PART}${ROOTIDX}" /mnt/.snapshots > /dev/null 2>&1
	mount -o compress=zstd:1,subvol=@cache "${PART}${ROOTIDX}" /mnt/var/cache > /dev/null 2>&1
	mount -o compress=zstd:1,subvol=@log "${PART}${ROOTIDX}" /mnt/var/log > /dev/null 2>&1
	mount "${PART}1" /mnt/efi > /dev/null 2>&1
}

######################################################################
# Base system & configuration
######################################################################
install_base_system() {
	log "Installing base system (this may take a while)..."
	pacstrap -K /mnt base linux linux-firmware > /dev/null 2>&1
}

generate_system_files() {
	log "Generating system files..."
	genfstab -U /mnt >> /mnt/etc/fstab
	echo "${HOSTNAME}" > /mnt/etc/hostname
	cat <<EOF > /mnt/etc/hosts
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF
	echo "${MLOCALE}" > /mnt/etc/locale.gen
	if [[ -n "${SLOCALE}" && "${SLOCALE}" != "${MLOCALE}" ]]; then
		echo "${SLOCALE}" >> /mnt/etc/locale.gen
	fi
	echo LANG=${MLOCALE} > /mnt/etc/locale.conf
	arch-chroot /mnt locale-gen > /dev/null 2>&1
	echo KEYMAP=${KEYMAP} > /mnt/etc/vconsole.conf
	arch-chroot /mnt ln -sf "/usr/share/zoneinfo/${TIMEZONE}" /etc/localtime
}

install_additional_packages() {
	log "Installing additional packages (this may take a while)..."
	arch-chroot /mnt pacman -Sy --noconfirm \
		"${CPUTYPE}"-ucode \
		base-devel \
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
}

set_mirrors() {
	log "Setting mirrors..."
	arch-chroot /mnt reflector --country "${COUNTRY}" --age 6 --protocol https --sort rate --save /etc/pacman.d/mirrorlist > /dev/null 2>&1 || true
}

######################################################################
# Users & shell setup
######################################################################
setup_users() {
	log "Setting up user account..."
	echo "root:${ROOTPASS}" | chpasswd --root /mnt > /dev/null 2>&1
	arch-chroot /mnt useradd -c "${USERFULLNAME}" -m -G wheel -s /usr/bin/zsh "${USERNAME}" > /dev/null 2>&1
	echo "${USERNAME}:${USERPASS}" | chpasswd --root /mnt > /dev/null 2>&1
	arch-chroot /mnt sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers > /dev/null 2>&1
}

setup_shell_and_theme() {
	log "Setting up Shell (Oh My Zsh & Oh My Posh)..."
	arch-chroot /mnt su - "${USERNAME}" -s /bin/bash <<'EOL'
set -euo pipefail
touch "$HOME/.zshrc" > /dev/null 2>&1
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | bash -s -- --unattended > /dev/null 2>&1
curl -s https://ohmyposh.dev/install.sh | bash -s > /dev/null 2>&1
"$HOME/.local/bin/oh-my-posh" font install meslo > /dev/null 2>&1 || true
mv "$HOME/.zshrc" "$HOME/.zshrc.bak" > /dev/null 2>&1 || true
EOL
}

apply_dotfiles() {
	log "Configuring Shell from repo dotfiles..."
	arch-chroot /mnt su - "${USERNAME}" -s /bin/bash <<'EOL'
set -euo pipefail
cd "/var/tmp" > /dev/null 2>&1
git clone https://github.com/RyanTheTide/LinuxConfigurations.git > /dev/null 2>&1
cd LinuxConfigurations > /dev/null 2>&1
cp -r dotfiles/. "$HOME" > /dev/null 2>&1
history -c > /dev/null 2>&1 || true
EOL
}

######################################################################
# Services & boot manager
######################################################################
enable_services() {
	log "Enabling services..."
	arch-chroot /mnt systemctl enable fstrim.timer > /dev/null 2>&1
	arch-chroot /mnt systemctl enable NetworkManager > /dev/null 2>&1
	arch-chroot /mnt systemctl enable reflector.timer > /dev/null 2>&1
}

install_refind() {
	log "Installing rEFInd..."
	arch-chroot /mnt refind-install > /dev/null 2>&1
	rm -f /mnt/boot/refind_linux.conf > /dev/null 2>&1 || true
	touch /mnt/boot/refind_linux.conf
	cat > /mnt/boot/refind_linux.conf <<EOF
"Standard Boot"  "root=PARTUUID=${ROOTPARTUUID} rw add_efi_memmap quiet rootflags=subvol=@ initrd=@\\boot\\${CPUTYPE}-ucode.img initrd=@\\boot\\initramfs-linux.img"
"Fallback Boot"  "root=PARTUUID=${ROOTPARTUUID} rw add_efi_memmap rootflags=subvol=@ initrd=@\\boot\\${CPUTYPE}-ucode.img initrd=@\\boot\\initramfs-linux-fallback.img"
"Terminal Boot"  "root=PARTUUID=${ROOTPARTUUID} rw add_efi_memmap rootflags=subvol=@ initrd=@\\boot\\${CPUTYPE}-ucode.img initrd=@\\boot\\initramfs-linux.img systemd.unit=multi-user.target"
EOF
	# Copy custom rEFInd configuration/theme from repo
	mv /mnt/efi/EFI/refind/refind.conf /mnt/efi/EFI/refind/refind.conf.bak || true
	cp -r /mnt/var/tmp/LinuxConfigurations/refind /mnt/efi/EFI/
}

cleanup() {
	rm -rf /mnt/var/tmp/LinuxConfigurations || true
	log "Installation complete!"
}

######################################################################
# Main
######################################################################
main() {
	require_root
	parse_args "$@"
	select_disk
	prompt_system_config
	compute_partition_layout
	confirm_summary

	partition_disk
	format_filesystems
	create_btrfs_layout_and_mount

	install_base_system
	generate_system_files
	install_additional_packages
	set_mirrors

	setup_users
	setup_shell_and_theme
	apply_dotfiles
	enable_services

	install_refind
	cleanup
}

main "$@"
