# Arch Installer Script by RyanTheTide!

# General Information
This script was created as a way to speed up all my Arch installs. It can be ran via the command `sh -c "$(curl -fsSL https://raw.githubusercontent.com/RyanTheTide/LinuxConfigurations/refs/heads/main/scripts/install.sh)"`.
The install will create a btrfs partition with 5 subvolumes (Root, Home, Snapshots, Cache, Log), two necessary partitions for windows and install rEFInd with a custom theme on the EFI partition.

The packages installed are as follows:
* base, linux, linux-firmware
* CPU-ucode
* base-devel
* btrfs-progs
* efibootmgr, refind
* networkmanager
* bluez
* mesa
* nano
* sudo
* zsh, zsh-completions, zsh-autosuggestions, zsh-syntax-highlighting
* git, unzip
* reflector
* fastfetch

Please note, this script is heavily personal and as such hardcodes the region, locale (and additionally the en-US one), keymap, dual-boot percentage and other things. Please edit these either by cloning or downloading before blindly running. If you don't and are not Australian and within Sydney, expect to see spiders, snakes, kangaroos and dropbears. **Don't blindly run scripts without rtfm and checking the code yourself**.

## Known Issues
* When running the Arch Installer script in a Virtual Machine the rEFInd resolution defaults to the highest possible resolution for the virtual display adapter. To fix this change the refind.conf resolution value to something like `resolution 1280 720` or `resolution 1920 1080`.

## Planned Improvements to Arch Installer Script.
* Add the timezone, locale and keymap as easily adjustable variables.
* Allow the percentage split for Windows and Arch to be changed and furthermore add the option to disable the dual-booting functionality (disabiling rEFInd and using systemd-boot).
* Add NVIDIA and VirtualBox driver support as an option alongside the existing AMD defaults.
* Refactor code into functions for easy adjustment and feature inclusions/changes on the fly.
* Make printed/echoed text colourful!
* Auto-detect intel/amd.
* Add an unattended option with an easily modified config.
* Whatever else is suggested!
